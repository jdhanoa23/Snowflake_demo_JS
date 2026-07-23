# Metadata-driven incremental upsert from Landing to Raw layer in Snowflake


import uuid
from datetime import datetime, timezone
from snowflake.snowpark.context import get_active_session


def get_connection():
    """Get a cursor from the active Snowpark session."""
    session = get_active_session()
    session.sql("USE DATABASE ADVENTUREWORKSDB").collect()
    session.sql("USE SCHEMA PUBLIC").collect()
    return session.connection.cursor()


def get_active_configs(cur):
    """Fetch all active pipeline configurations."""
    cur.execute("""
        SELECT CONFIG_ID, SOURCE_SCHEMA, SOURCE_TABLE,
               TARGET_SCHEMA, TARGET_TABLE,
               PRIMARY_KEY_COLUMNS, WATERMARK_COLUMN, LOAD_TYPE
        FROM ADVENTUREWORKSDB.PUBLIC.PIPELINE_CONFIG
        WHERE IS_ACTIVE = TRUE
        ORDER BY CONFIG_ID
    """)
    columns = [desc[0] for desc in cur.description]
    return [dict(zip(columns, row)) for row in cur.fetchall()]


def get_table_columns(cur, schema, table):
    """Get column list for a table using SHOW COLUMNS."""
    cur.execute(f"SHOW COLUMNS IN TABLE ADVENTUREWORKSDB.{schema}.{table}")
    rows = cur.fetchall()
    col_names = [row[2] for row in rows]
    return col_names


def ensure_target_table(cur, config, columns):
    """Create target table in RAW schema if it doesn't exist."""
    target = f"ADVENTUREWORKSDB.{config['TARGET_SCHEMA']}.{config['TARGET_TABLE']}"
    source = f"ADVENTUREWORKSDB.{config['SOURCE_SCHEMA']}.{config['SOURCE_TABLE']}"
    cur.execute(f"CREATE TABLE IF NOT EXISTS {target} LIKE {source}")
    for col, dtype in [("_LOADED_AT", "TIMESTAMP_NTZ"), ("_UPDATED_AT", "TIMESTAMP_NTZ")]:
        try:
            cur.execute(f"ALTER TABLE {target} ADD COLUMN {col} {dtype}")
        except Exception:
            pass


def build_merge_sql(config, columns):
    """Build a MERGE statement for upsert based on config."""
    source = f"ADVENTUREWORKSDB.{config['SOURCE_SCHEMA']}.{config['SOURCE_TABLE']}"
    target = f"ADVENTUREWORKSDB.{config['TARGET_SCHEMA']}.{config['TARGET_TABLE']}"
    pk_cols = [c.strip() for c in config['PRIMARY_KEY_COLUMNS'].split(',')]

    join_cond = " AND ".join([f"tgt.{pk} = src.{pk}" for pk in pk_cols])

    # Update columns (exclude PKs)
    update_cols = [c for c in columns if c not in pk_cols]
    if update_cols:
        update_set = ", ".join([f"tgt.{c} = src.{c}" for c in update_cols])
        update_set += ", tgt._UPDATED_AT = CURRENT_TIMESTAMP()"
    else:
        update_set = "tgt._UPDATED_AT = CURRENT_TIMESTAMP()"

    # Insert columns and values
    all_cols = columns + ["_LOADED_AT", "_UPDATED_AT"]
    insert_cols = ", ".join(all_cols)
    insert_vals = ", ".join([f"src.{c}" for c in columns]) + ", CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()"

    # Watermark filter for incremental loads (applied inside the USING subquery)
    where_clause = ""
    if config['LOAD_TYPE'] == 'INCREMENTAL' and config.get('WATERMARK_COLUMN'):
        wm = config['WATERMARK_COLUMN']
        where_clause = f"""
        WHERE {wm} > COALESCE(
            (SELECT MAX({wm}) FROM {target}), '1900-01-01'::DATE
        )"""

    merge_sql = f"""
    MERGE INTO {target} AS tgt
    USING (
        SELECT * FROM {source}
        {where_clause}
    ) AS src
    ON {join_cond}
    WHEN MATCHED THEN
        UPDATE SET {update_set}
    WHEN NOT MATCHED THEN
        INSERT ({insert_cols})
        VALUES ({insert_vals})
    """
    return merge_sql


def _sql_escape(val):
    """Escape a value for inline SQL insertion."""
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    if isinstance(val, datetime):
        return f"'{val.strftime('%Y-%m-%d %H:%M:%S')}'"
    return "'" + str(val).replace("'", "''") + "'"


def log_audit(cur, run_id, config, start_time, rows_inserted, rows_updated, status, error_msg=None):
    """Insert a record into the audit table."""
    end_time = datetime.now(timezone.utc)
    sql = f"""
        INSERT INTO ADVENTUREWORKSDB.PUBLIC.PIPELINE_AUDIT
            (RUN_ID, CONFIG_ID, SOURCE_TABLE, TARGET_TABLE, LOAD_TYPE,
             START_TIME, END_TIME, ROWS_INSERTED, ROWS_UPDATED, STATUS, ERROR_MESSAGE)
        VALUES (
            {_sql_escape(run_id)},
            {_sql_escape(config['CONFIG_ID'])},
            {_sql_escape(config['SOURCE_TABLE'])},
            {_sql_escape(config['TARGET_TABLE'])},
            {_sql_escape(config['LOAD_TYPE'])},
            {_sql_escape(start_time)},
            {_sql_escape(end_time)},
            {_sql_escape(rows_inserted)},
            {_sql_escape(rows_updated)},
            {_sql_escape(status)},
            {_sql_escape(error_msg)}
        )
    """
    cur.execute(sql)


def run_pipeline():
    """Main entry point: iterate configs and run upserts."""
    run_id = str(uuid.uuid4())
    cur = get_connection()

    print(f"=== Pipeline Run: {run_id} ===")
    print(f"Started at: {datetime.now(timezone.utc).isoformat()}")
    print("-" * 60)

    configs = get_active_configs(cur)
    print(f"Found {len(configs)} active table config(s)\n")

    for config in configs:
        table_name = config['SOURCE_TABLE']
        start_time = datetime.now(timezone.utc)
        print(f"Processing: {config['SOURCE_SCHEMA']}.{table_name} -> {config['TARGET_SCHEMA']}.{config['TARGET_TABLE']} [{config['LOAD_TYPE']}]")

        try:
            columns = get_table_columns(cur, config['SOURCE_SCHEMA'], table_name)
            ensure_target_table(cur, config, columns)

            merge_sql = build_merge_sql(config, columns)
            cur.execute(merge_sql)

            # MERGE returns (rows_inserted, rows_updated)
            result = cur.fetchone()
            rows_inserted = result[0] if result else 0
            rows_updated = result[1] if result and len(result) > 1 else 0

            log_audit(cur, run_id, config, start_time, rows_inserted, rows_updated, "SUCCESS")
            print(f"  SUCCESS - inserted: {rows_inserted}, updated: {rows_updated}")

        except Exception as e:
            error_msg = str(e)[:4000]
            try:
                log_audit(cur, run_id, config, start_time, 0, 0, "FAILED", error_msg)
            except Exception:
                pass
            print(f"  FAILED - {error_msg[:200]}")

    print("\n" + "-" * 60)
    print(f"Pipeline run {run_id} complete at {datetime.now(timezone.utc).isoformat()}")
    cur.close()


if __name__ == "__main__":
    run_pipeline()
