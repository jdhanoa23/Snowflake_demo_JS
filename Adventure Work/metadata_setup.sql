-- Metadata-driven pipeline configuration and audit tables for Landing-to-Raw ingestion
-- Co-authored with CoCo

---------------------------------------------------------------
-- 1. PIPELINE_CONFIG: drives which tables get ingested and how
---------------------------------------------------------------
CREATE OR REPLACE TABLE ADVENTUREWORKSDB.PUBLIC.PIPELINE_CONFIG (
    CONFIG_ID           NUMBER AUTOINCREMENT PRIMARY KEY,
    SOURCE_SCHEMA       VARCHAR(128)   DEFAULT 'LANDING',
    SOURCE_TABLE        VARCHAR(128)   NOT NULL,
    TARGET_SCHEMA       VARCHAR(128)   DEFAULT 'RAW',
    COLUMNS             VARCHAR   ,
    TARGET_TABLE        VARCHAR(128)   NOT NULL,
    PRIMARY_KEY_COLUMNS VARCHAR(500)   NOT NULL,   -- comma-separated PK columns for MERGE
    WATERMARK_COLUMN    VARCHAR(128),              -- column used for incremental detection (e.g. ORDERDATE, MODIFIEDDATE)
    IS_ACTIVE           BOOLEAN        DEFAULT TRUE,
    LOAD_TYPE           VARCHAR(20)    DEFAULT 'INCREMENTAL', -- FULL or INCREMENTAL
    CREATED_AT          TIMESTAMP_NTZ  DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT          TIMESTAMP_NTZ  DEFAULT CURRENT_TIMESTAMP()
);

---------------------------------------------------------------
-- 2. PIPELINE_AUDIT: logs every run for observability
---------------------------------------------------------------
CREATE OR REPLACE TABLE ADVENTUREWORKSDB.PUBLIC.PIPELINE_AUDIT (
    AUDIT_ID        NUMBER AUTOINCREMENT PRIMARY KEY,
    RUN_ID          VARCHAR(36)    NOT NULL,   -- UUID per batch run
    CONFIG_ID       NUMBER         NOT NULL,
    SOURCE_TABLE    VARCHAR(128),
    TARGET_TABLE    VARCHAR(128),
    LOAD_TYPE       VARCHAR(20),
    START_TIME      TIMESTAMP_NTZ,
    END_TIME        TIMESTAMP_NTZ,
    ROWS_INSERTED   NUMBER DEFAULT 0,
    ROWS_UPDATED    NUMBER DEFAULT 0,
    STATUS          VARCHAR(20),   -- SUCCESS / FAILED
    ERROR_MESSAGE   VARCHAR(16777216),
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

---------------------------------------------------------------
-- 3. Seed PIPELINE_CONFIG with your 8 landing tables
---------------------------------------------------------------
INSERT INTO ADVENTUREWORKSDB.PUBLIC.PIPELINE_CONFIG
    (SOURCE_TABLE, TARGET_TABLE, PRIMARY_KEY_COLUMNS, WATERMARK_COLUMN, LOAD_TYPE, Columns)
VALUES
    ('CUSTOMERS',             'CUSTOMERS',             'CUSTOMERID',                        NULL,        'FULL' ,  '['CUSTOMERID','FIRSTNAME', 'LASTNAME', 'FULLNAME']'         ),
    ('EMPLOYEE',              'EMPLOYEE',              'EMPLOYEEID',                        NULL,        'FULL'           ),
    ('ORDERS',                'ORDERS',                'SALESORDERID,SALESORDERDETAILID',   'ORDERDATE', 'INCREMENTAL'    ),
    ('PRODUCTCATEGORIES',     'PRODUCTCATEGORIES',     'CATEGORYID',                        NULL,        'FULL'            ),
    ('PRODUCTS',              'PRODUCTS',              'PRODUCTID',                         NULL,        'FULL'            ),
    ('PRODUCTSUBCATEGORIES',  'PRODUCTSUBCATEGORIES',  'SUBCATEGORYID',                     NULL,        'FULL'            ),
    ('VENDORPRODUCT',         'VENDORPRODUCT',         'PRODUCTID,VENDORID',                NULL,        'FULL'           ),
    ('VENDORS',               'VENDORS',              'VENDORID',                           NULL,        'FULL'           );
