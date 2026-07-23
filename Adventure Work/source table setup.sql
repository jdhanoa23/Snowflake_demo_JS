-- Source table setup for AdventureWorks database migration to Snowflake
-- Co-authored with CoCo
CREATE TABLE ADVENTUREWORKSDB.PUBLIC.metadata_adventureworks (
  database_name VARCHAR(128),
  table_name VARCHAR(128),
  column_name VARCHAR(128),
  data_type VARCHAR(64),
  character_maximum_length BIGINT,
  numeric_precision BIGINT,
  numeric_scale BIGINT,
  is_nullable VARCHAR(3),
  column_default VARCHAR(16777216),
  instance_name VARCHAR(128),
  source_name VARCHAR(128),
  schema_name VARCHAR(128)
);


CREATE TABLE ADVENTUREWORKSDB.PUBLIC.METADATA_PIPELINE_AUDIT
(
RUN_ID STRING,
PIPELINE_ID INTEGER,
TABLE_NAME STRING,
START_TIME TIMESTAMP,
END_TIME TIMESTAMP,
STATUS STRING,
ROWS_INSERTED NUMBER,
ROWS_UPDATED NUMBER,
ERROR_MESSAGE STRING
);

CREATE TABLE ADVENTUREWORKSDB.PUBLIC.AutoLoaderMetadata (
    TableName              VARCHAR(200),
    PrimaryKey             VARCHAR(500),
    SchemaOwner            VARCHAR(100),
    BasePath               VARCHAR,
    SchemaLocation         VARCHAR,
    CheckpointPath         VARCHAR,
    Tagss                  VARCHAR(100),
    Sources                VARCHAR(100),
    IsActive               BOOLEAN,
    DestinationCatalog     VARCHAR(100),
    DestinationSchema      VARCHAR(100),
    DestinationTableName   VARCHAR(200),
    FileFormat             VARCHAR(50),
    PathGlobFilter         VARCHAR(100),
    SchemaOverride         VARCHAR,
    NullValue              VARCHAR(100),
    LoadType               VARCHAR(50),
    BatchKeyColumns        VARCHAR(500),
    BatchKeyPathKeys       VARCHAR(500),
    EmptyValue             VARCHAR(100),
    MultiLine              BOOLEAN,
    Quote                  VARCHAR(10),
    Escapes                VARCHAR(10),
    IsConcurrent           BOOLEAN
);