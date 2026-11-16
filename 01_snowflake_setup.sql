-- =============================================================
-- 01 · Snowflake setup and data load
-- Creates the warehouse, database, schema, table, file format and
-- internal stage, then loads the stacked CSV with COPY INTO.
-- =============================================================

-- Compute: smallest warehouse, suspends after 60s idle to save credits
CREATE OR REPLACE WAREHOUSE NYC_TAXI_WH WITH
  WAREHOUSE_SIZE      = XSMALL
  AUTO_SUSPEND        = 60
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE NYC_TAXI_WH;

-- Storage: database and schema
CREATE DATABASE IF NOT EXISTS NYC_TAXI_DATA;
USE DATABASE NYC_TAXI_DATA;

CREATE SCHEMA IF NOT EXISTS YELLOW_TRIPS;
USE SCHEMA YELLOW_TRIPS;

SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();

-- Target table (22 columns, matching the stacked CSV)
CREATE OR REPLACE TABLE yellow_tripdata (
  VendorID              FLOAT,
  tpep_pickup_datetime  TIMESTAMP,
  tpep_dropoff_datetime TIMESTAMP,
  passenger_count       FLOAT,
  trip_distance         FLOAT,
  RatecodeID            FLOAT,
  store_and_fwd_flag    VARCHAR(1),
  PULocationID          FLOAT,
  DOLocationID          FLOAT,
  payment_type          FLOAT,
  fare_amount           FLOAT,
  extra                 FLOAT,
  mta_tax               FLOAT,
  tip_amount            FLOAT,
  tolls_amount          FLOAT,
  improvement_surcharge FLOAT,
  total_amount          FLOAT,
  congestion_surcharge  FLOAT,
  Airport_fee           FLOAT,
  cbd_congestion_fee    FLOAT,
  month                 FLOAT,
  year                  FLOAT
);

-- File format: CSV with header, blanks/NA treated as NULL
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE                           = 'CSV'
  FIELD_DELIMITER                = ','
  SKIP_HEADER                    = 1
  NULL_IF                        = ('NULL', 'null', '', 'NA')
  FIELD_OPTIONALLY_ENCLOSED_BY   = '"'
  TRIM_SPACE                     = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  EMPTY_FIELD_AS_NULL            = TRUE
  DATE_FORMAT                    = 'AUTO'
  TIMESTAMP_FORMAT               = 'AUTO';

-- Internal stage for the upload
CREATE OR REPLACE STAGE taxi_stage
  FILE_FORMAT = csv_format
  COMMENT     = 'Stage for yellow taxi trip data files';

SHOW STAGES LIKE 'taxi_stage';

-- Upload data/processed/yellow_tripdata_stacked.csv to @taxi_stage
-- (Snowsight UI, or SnowSQL:  PUT file://data/processed/yellow_tripdata_stacked.csv @taxi_stage;)
LIST @taxi_stage;

COPY INTO yellow_tripdata
  FROM        @taxi_stage/yellow_tripdata_stacked.csv
  FILE_FORMAT = csv_format
  ON_ERROR    = 'CONTINUE'
  PURGE       = FALSE;

-- Verify the load: expect 45,785 rows (Aug 22,797 / Sep 22,988)
SELECT COUNT(*) AS total_rows FROM yellow_tripdata;

SELECT month,
       COUNT(*)                  AS row_count,
       MIN(tpep_pickup_datetime) AS earliest_trip,
       MAX(tpep_pickup_datetime) AS latest_trip
FROM yellow_tripdata
GROUP BY month
ORDER BY month;

SELECT * FROM yellow_tripdata LIMIT 10;
