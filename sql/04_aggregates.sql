-- Byg et materialiseret aggregate: Daglig omsætning pr. bydel
CREATE TABLE IF NOT EXISTS agg_daily_borough_revenue AS
SELECT 
    d.date_key,
    z.Borough,
    COUNT(*) AS total_trips,
    SUM(f.total_amount) AS total_revenue,
    SUM(f.trip_distance) AS total_distance,
    ROUND(AVG(f.total_amount), 2) AS avg_trip_revenue
FROM fact_trip f
JOIN dim_date d ON f.pickup_date_key = d.date_key
JOIN dim_zone z ON f.pickup_zone_key = z.LocationID
GROUP BY d.date_key, z.Borough;

-- Kontrollér aggregatets Grain
-- Grain før: 1 række = 1 taxitur.
-- Grain efter: 1 række = 1 specifik dato i én specifik bydel.
SELECT COUNT(*) AS antal_aggregerede_raekker 
FROM agg_daily_borough_revenue;

-- Spørgsmål aggregatet KAN besvare (Hvor meget omsatte Manhattan for d. 5. januar?)
SELECT total_revenue 
FROM agg_daily_borough_revenue 
WHERE Borough = 'Manhattan' AND date_key = '2025-01-05';

DROP TABLE IF EXISTS agg_hourly_borough_revenue;

-- Hourly revenue per day per borough (for januar 2025)
CREATE TABLE agg_hourly_borough_revenue AS
SELECT 
    DATE_TRUNC('hour', f.tpep_pickup_datetime) AS pickup_hour,
    z.Borough,
    COUNT(*) AS total_trips,
    SUM(f.total_amount) AS hourly_revenue
FROM fact_trip f
JOIN dim_zone z ON f.pickup_zone_key = z.LocationID
WHERE f.tpep_pickup_datetime >= '2025-01-01' 
  AND f.tpep_pickup_datetime < '2025-02-01'
GROUP BY pickup_hour, z.Borough;

-- 4. Spørgsmål aggregatet IKKE kan besvare (Kræver mere detaljerede data)
-- Hvor mange ture startede specifikt kl. 14:30 i Manhattan?
-- (Dette er umuligt, da tidspunkt-detaljen gik tabt i 'GROUP BY d.date_key').