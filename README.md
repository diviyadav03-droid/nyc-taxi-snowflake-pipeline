# NYC Taxi Data Pipeline & Snowflake Analysis

An end-to-end batch data pipeline: two months of NYC Yellow Taxi trip records are cleaned and stacked in Alteryx, loaded into a Snowflake warehouse, and analyzed with SQL. It ends with a data-quality review of how invalid records distort the headline numbers.

> **Context:** Academic group project for MBA 552 (Data Engineering, Management & Warehousing), NC State University, Spring 2026. I designed and built the data pipeline, Snowflake setup and SQL analysis in this repository.

**Tools:** Alteryx · Snowflake (warehouse, stage, file format, `COPY INTO`) · SQL · Python (pandas, for a code reproduction of the Alteryx step)

---

## Pipeline

```
data/raw/                     scripts/                    data/processed/                 Snowflake
yellow_tripdata_2025-08.csv ─┐
                             ├─► Alteryx workflow   ─►  yellow_tripdata_stacked.csv ─► @taxi_stage ─► COPY INTO yellow_tripdata ─► SQL analysis
yellow_tripdata_2025-09.csv ─┘   drop empty rows/cols      45,785 rows × 22 cols
                                 stack Aug + Sep
```

| Step | What happens | File |
|---|---|---|
| 1. Clean & stack | Built in **Alteryx**: drop fully empty rows (2,203 Aug, 2,012 Sep) and the fully empty `mileage` column, then stack both months | Alteryx workflow; reproduced in code in `scripts/stack_trip_data.py` |
| 2. Load | Create warehouse, database, schema, table, CSV file format and internal stage; load with `COPY INTO` and verify row counts | `sql/01_snowflake_setup.sql` |
| 3. Analyze | 10 business questions on volume, distance, fares, payment mix, vendors, revenue and tips | `sql/02_analysis_queries.sql` |
| 4. Data quality | Profile invalid records and recompute key metrics on valid trips only | `sql/03_data_quality_checks.sql` |

## Results

| # | Question | Result |
|---|---|---|
| 1 | Total trips | **45,785** |
| 2 | Trips by month | August 22,797 · September 22,988 |
| 3 | Average trip distance | 2.51 miles |
| 4 | Average fare | $15.07 |
| 5 | Trips by payment method | Credit card 28,224 · Flex Fare 11,665 · Cash 4,381 · Dispute 1,202 · No charge 313 |
| 6 | Average passengers per trip | 1.28 |
| 7 | Trips by vendor | Curb Mobility 36,611 · Creative Mobile Technologies 8,490 · Helix 645 · Myle Technologies 39 |
| 8 | Total revenue | $1,036,321.46 |
| 9 | Longest trip | 10.0 miles (see data-quality note below) |
| 10 | Average tip | $2.31 |

## Data quality findings

The headline queries average over every row. A closer look at the data shows several record types that skew those results:

| Check | Records |
|---|---|
| Negative fare amount (refunds / reversals) | 3,055 |
| Negative total amount | 949 |
| Zero trip distance | 1,419 |
| Drop-off at or before pick-up | 647 |
| Missing passenger count | 11,665 (all of them Flex Fare trips) |

**Valid trips vs. all rows** (valid = positive distance, non-negative fare and total, drop-off after pick-up):

| | Trips | Avg distance | Avg fare | Avg tip | Revenue |
|---|---|---|---|---|---|
| All rows | 45,785 | 2.51 mi | $15.07 | $2.31 | $1,036,321.46 |
| Valid trips only | 40,949 | 2.55 mi | **$16.48** | **$2.48** | $994,951.97 |

Takeaways:
- About **10.6%** of records (4,836) fail at least one validity rule. Excluding them raises the average fare by about 9% and the average tip by about 7%.
- The "longest trip" returned by `ORDER BY trip_distance DESC LIMIT 1` is a **refund** (fare −$41.50). Distances in this sample top out at 10.0 miles, and **24 trips tie** at that maximum, so `LIMIT 1` picks one arbitrarily. Query D in `03_data_quality_checks.sql` returns all 21 valid trips at the maximum instead.
- Passenger count is missing for every Flex Fare trip, so the 1.28 average reflects only non-Flex trips. SQL `AVG` silently ignores NULLs.

## Repository structure

```
├── data/
│   ├── raw/                  # monthly source files (Aug, Sep 2025)
│   └── processed/            # stacked file loaded into Snowflake
├── scripts/
│   └── stack_trip_data.py    # Python reproduction of the Alteryx clean + stack step
└── sql/
    ├── 01_snowflake_setup.sql
    ├── 02_analysis_queries.sql
    └── 03_data_quality_checks.sql
```

## How to run

The original clean-and-stack step was built in Alteryx. To rerun it without Alteryx, use the Python version, which produces an identical file:

```bash
pip install pandas
python scripts/stack_trip_data.py      # writes data/processed/yellow_tripdata_stacked.csv
```

Then, in a Snowflake worksheet, run `sql/01_snowflake_setup.sql`. Upload the stacked CSV to `@taxi_stage` when the script reaches the `LIST`/`COPY INTO` step. After that, run `02` and `03`.

## Data source

[NYC Taxi & Limousine Commission (TLC) Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), Yellow Taxi, August and September 2025. The files here are 25,000-row monthly samples provided for the course. Field definitions are in the TLC [Yellow Trips data dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf).
