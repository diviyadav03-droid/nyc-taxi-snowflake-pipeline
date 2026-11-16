-- =============================================================
-- 02 · Analysis queries (results from Snowflake shown in comments)
-- Table: NYC_TAXI_DATA.YELLOW_TRIPS.yellow_tripdata (45,785 trips)
-- =============================================================

-- Q1. How many total taxi trips are in the dataset?            -> 45,785
SELECT COUNT(*) AS total_trips
FROM yellow_tripdata;

-- Q2. Total trips in each month.                               -> Aug 22,797 | Sep 22,988
SELECT month,
       COUNT(*) AS trip_count
FROM yellow_tripdata
GROUP BY month
ORDER BY month;

-- Q3. Average trip distance (miles).                           -> 2.51
SELECT ROUND(AVG(trip_distance), 2) AS avg_trip_distance_miles
FROM yellow_tripdata;

-- Q4. Average fare amount.                                     -> $15.07
SELECT ROUND(AVG(fare_amount), 2) AS avg_fare_amount
FROM yellow_tripdata;

-- Q5. Trips by payment method, most to least popular.
--     Credit Card 28,224 | Flex Fare 11,665 | Cash 4,381 | Dispute 1,202 | No Charge 313
SELECT payment_type,
       CASE payment_type
         WHEN 0 THEN 'Flex Fare'
         WHEN 1 THEN 'Credit Card'
         WHEN 2 THEN 'Cash'
         WHEN 3 THEN 'No Charge'
         WHEN 4 THEN 'Dispute'
         WHEN 5 THEN 'Unknown'
         WHEN 6 THEN 'Voided Trip'
       END AS payment_name,
       COUNT(*) AS trip_count
FROM yellow_tripdata
GROUP BY payment_type
ORDER BY trip_count DESC;

-- Q6. Average passengers per trip.                             -> 1.28
--     Note: AVG ignores NULLs; passenger_count is NULL on all 11,665 Flex Fare trips.
SELECT ROUND(AVG(passenger_count), 2) AS avg_passengers_per_trip
FROM yellow_tripdata;

-- Q7. Trips completed by each vendor.
--     Curb Mobility 36,611 | Creative Mobile Technologies 8,490 | Helix 645 | Myle Technologies 39
SELECT VendorID,
       CASE VendorID
         WHEN 1 THEN 'Creative Mobile Technologies, LLC'
         WHEN 2 THEN 'Curb Mobility, LLC'
         WHEN 6 THEN 'Myle Technologies Inc'
         WHEN 7 THEN 'Helix'
       END AS vendor_name,
       COUNT(*) AS trip_count
FROM yellow_tripdata
GROUP BY VendorID
ORDER BY trip_count DESC;

-- Q8. Total revenue from all trips.                            -> $1,036,321.46
SELECT ROUND(SUM(total_amount), 2) AS total_revenue
FROM yellow_tripdata;

-- Q9. Longest trip in the dataset.
--     -> 10.0 mi, 2025-08-18 01:23, fare -$41.50, total -$45.75 (a refund / reversal)
--     Note: 24 trips tie at the 10.0-mile maximum, so LIMIT 1 returns one of them arbitrarily.
--     See 03_data_quality_checks.sql for a version that handles ties and excludes refunds.
SELECT VendorID,
       tpep_pickup_datetime,
       tpep_dropoff_datetime,
       trip_distance,
       fare_amount,
       total_amount
FROM yellow_tripdata
ORDER BY trip_distance DESC
LIMIT 1;

-- Q10. Average tip amount.                                     -> $2.31
SELECT ROUND(AVG(tip_amount), 2) AS avg_tip_amount
FROM yellow_tripdata;
