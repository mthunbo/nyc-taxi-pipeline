-- 1. Byg dim_zone
CREATE TABLE IF NOT EXISTS dim_zone AS
SELECT 
    LocationID,
    Borough,
    Zone,
    service_zone
FROM read_csv('data/raw/taxi_zone_lookup.csv');

-- 2. Kontrollér at zone-nøglen er entydig (Forventer samme tal i begge)
SELECT 
    COUNT(*) AS total_zones,
    COUNT(DISTINCT LocationID) AS unique_zone_keys
FROM dim_zone;

-- 3. Byg dim_date så den dækker BÅDE pickup og dropoff
CREATE TABLE IF NOT EXISTS dim_date AS
WITH raw_dates AS (
    SELECT CAST(tpep_pickup_datetime AS DATE) AS date_val FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
    UNION
    SELECT CAST(tpep_dropoff_datetime AS DATE) AS date_val FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
)
SELECT 
    date_val AS date_key,
    EXTRACT(YEAR FROM date_val) AS year,
    EXTRACT(MONTH FROM date_val) AS month,
    EXTRACT(DAY FROM date_val) AS day,
    DAYOFWEEK(date_val) AS weekday
FROM raw_dates
WHERE date_val IS NOT NULL;

-- 4. Kontrollér dim_date
SELECT 
    COUNT(*) AS total_dates,
    MIN(date_key) AS tidligste_dato,
    MAX(date_key) AS seneste_dato
FROM dim_date;