from snowflake.snowpark import session

import uuid
from datetime import datetime

from snowflake.snowpark import Session

import uuid

from datetime import datetime

def main(session: Session):

    metadata = session.sql("""

        SELECT *

        FROM ADVENTUREWORKSDB.PUBLIC.METADATA_ADVENTUREWORKS

        WHERE ACTIVE_FLAG = TRUE

    """).collect()

    for row in metadata:

        pipeline_id = row["PIPELINE_ID"]

        source_db = row["SOURCE_DATABASE"]

        source_schema = row["SOURCE_SCHEMA"]

        source_table = row["SOURCE_TABLE"]

        target_db = row["TARGET_DATABASE"]

        target_schema = row["TARGET_SCHEMA"]

        target_table = row["TARGET_TABLE"]

        pk = row["PRIMARY_KEY"]

        inc_column = row["INCREMENTAL_COLUMN"]

        last_load = row["LAST_SUCCESSFUL_LOAD"]

        run_id = str(uuid.uuid4())

        start = datetime.now()

        try:

            sql = f"""

            MERGE INTO {target_db}.{target_schema}.{target_table} T

            USING (

                SELECT *

                FROM {source_db}.{source_schema}.{source_table}

                WHERE {inc_column} >

                '{last_load}'

            ) S

            ON T.{pk}=S.{pk}

            WHEN MATCHED THEN UPDATE SET

            """

            columns = session.table(

                f"{source_db}.INFORMATION_SCHEMA.COLUMNS"

            ).filter(

                f"TABLE_NAME='{source_table.upper()}'"

            ).collect()

            update_columns = []

            insert_columns = []

            insert_values = []

            for col in columns:

                name = col["COLUMN_NAME"]

                if name != pk:

                    update_columns.append(f"T.{name}=S.{name}")

                insert_columns.append(name)

                insert_values.append(f"S.{name}")

            sql += ",".join(update_columns)

            sql += """

            WHEN NOT MATCHED THEN INSERT(

            """

            sql += ",".join(insert_columns)

            sql += ") VALUES("

            sql += ",".join(insert_values)

            sql += ")"

            session.sql(sql).collect()

            session.sql(f"""

                UPDATE ADVENTUREWORKSDB.PUBLIC.METADATA_ADVENTUREWORKS

                SET LAST_SUCCESSFUL_LOAD=CURRENT_TIMESTAMP()

                WHERE PIPELINE_ID={pipeline_id}

            """).collect()

            end = datetime.now()

            session.sql(f"""

            INSERT INTO CONTROL_DB.METADATA.PIPELINE_AUDIT

            VALUES(

            '{run_id}',

            {pipeline_id},

            '{target_table}',

            '{start}',

            '{end}',

            'SUCCESS',

            NULL,

            NULL,

            NULL

            )

            """).collect()

        except Exception as ex:

            end = datetime.now()

            session.sql(f"""

            INSERT INTO CONTROL_DB.METADATA.PIPELINE_AUDIT

            VALUES(

            '{run_id}',

            {pipeline_id},

            '{target_table}',

            '{start}',

            '{end}',

            'FAILED',

            NULL,

            NULL,

            '{str(ex).replace("'","")}'

            )

            """).collect()

    return "Completed"
 

