-- 1. Implementér fact_trip
CREATE TABLE IF NOT EXISTS fact_trip AS
SELECT 
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    CAST(tpep_pickup_datetime AS DATE) AS pickup_date_key,
    CAST(tpep_dropoff_datetime AS DATE) AS dropoff_date_key,
    PULocationID AS pickup_zone_key,
    DOLocationID AS dropoff_zone_key,
    payment_type,
    trip_distance,
    total_amount,
    tip_amount
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- 2. Kontrollér fact mod raw
SELECT 
    (SELECT COUNT(*) FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')) AS raw_count,
    COUNT(*) AS fact_count
FROM fact_trip;

-- 3. Kontrollér relationsdækning
SELECT COUNT(*) AS ture_med_ukendt_pickup_zone
FROM fact_trip f
LEFT JOIN dim_zone z ON f.pickup_zone_key = z.LocationID
WHERE z.LocationID IS NULL;

-- 4. Analysequery 1: Omsætning og distancer pr. ugedag (bruger dim_date)
SELECT 
    d.weekday,
    COUNT(*) AS antal_ture,
    ROUND(AVG(f.trip_distance), 2) AS gns_distance,
    ROUND(SUM(f.total_amount), 2) AS samlet_omsaetning
FROM fact_trip f
JOIN dim_date d ON f.pickup_date_key = d.date_key
GROUP BY d.weekday
ORDER BY d.weekday;

-- 5. Analysequery 2: Top 5 afhentningsbydele mod lufthavne (bruger dim_zone)
SELECT 
    z.Borough AS afhentnings_bydel,
    COUNT(*) AS antal_ture,
    ROUND(AVG(f.tip_amount), 2) AS gns_drikkepenge,
    ROUND(SUM(f.total_amount), 2) AS samlet_omsaetning
FROM fact_trip f
JOIN dim_zone z ON f.pickup_zone_key = z.LocationID
GROUP BY z.Borough
ORDER BY samlet_omsaetning DESC
LIMIT 5;