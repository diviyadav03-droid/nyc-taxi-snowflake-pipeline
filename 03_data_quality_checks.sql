-- =============================================================
-- 03 · Data quality checks
-- The headline answers in 02 average over every row. These checks
-- profile records that distort those numbers, then re-run the key
-- metrics on valid trips only.
-- =============================================================

-- A. Profile suspect records
SELECT COUNT(*)                                             AS total_trips,
       COUNT_IF(fare_amount < 0)                            AS negative_fare,
       COUNT_IF(total_amount < 0)                           AS negative_total,
       COUNT_IF(trip_distance = 0)                          AS zero_distance,
       COUNT_IF(tpep_dropoff_datetime <= tpep_pickup_datetime) AS dropoff_not_after_pickup,
       COUNT_IF(passenger_count IS NULL)                    AS missing_passenger_count
FROM yellow_tripdata;

-- B. Where do the missing passenger counts come from?
--    (All NULL passenger_count rows are payment_type 0 / Flex Fare.)
SELECT payment_type,
       COUNT(*)                          AS trips,
       COUNT_IF(passenger_count IS NULL) AS missing_passenger_count
FROM yellow_tripdata
GROUP BY payment_type
ORDER BY payment_type;

-- C. Key metrics: all rows vs. valid trips only
--    Valid = positive distance, non-negative fare and total, dropoff after pickup
WITH flagged AS (
  SELECT *,
         (trip_distance > 0
          AND fare_amount >= 0
          AND total_amount >= 0
          AND tpep_dropoff_datetime > tpep_pickup_datetime) AS is_valid
  FROM yellow_tripdata
)
SELECT CASE WHEN is_valid THEN 'valid trips' ELSE 'excluded' END AS trip_group,
       COUNT(*)                          AS trips,
       ROUND(AVG(trip_distance), 2)      AS avg_distance_miles,
       ROUND(AVG(fare_amount), 2)        AS avg_fare,
       ROUND(AVG(tip_amount), 2)         AS avg_tip,
       ROUND(SUM(total_amount), 2)       AS total_revenue
FROM flagged
GROUP BY trip_group
ORDER BY trip_group DESC;

-- D. Longest valid trip(s), keeping ties instead of LIMIT 1
SELECT VendorID,
       tpep_pickup_datetime,
       tpep_dropoff_datetime,
       trip_distance,
       fare_amount,
       total_amount
FROM yellow_tripdata
WHERE fare_amount >= 0
  AND total_amount >= 0
  AND tpep_dropoff_datetime > tpep_pickup_datetime
QUALIFY RANK() OVER (ORDER BY trip_distance DESC) = 1
ORDER BY tpep_pickup_datetime;
