-- 20556 · Mandag · Version 1.0
-- Skriv selv dine queries. Find syntaks i DuckDB-dokumentationen.
-- Gem filen, og kør den med src/run_sql_file.py fra projektets rod.

-- 1. Dataundersøgelse
SELECT COUNT(*) AS samlet_antal_raekker
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

DESCRIBE SELECT * FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

SELECT *
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
LIMIT 5;

SELECT 
    MIN(tpep_pickup_datetime) AS tidligste_pickup,
    MAX(tpep_pickup_datetime) AS seneste_pickup
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

SELECT COUNT(DISTINCT PULocationID) AS antal_unikke_pickup_zoner
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- 2. Eget analysespørgsmål
-- En række repræsenterer samlet antal afhentninger og gennemsnitlig kørsel for en specifik time i døgnet (f.eks. kl. 14:00-14:59).
SELECT 
    EXTRACT(HOUR FROM tpep_pickup_datetime) AS time_paa_doegnet,
    COUNT(*) AS antal_afhentninger,
    ROUND(AVG(trip_distance), 2) AS gns_distance_miles
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
GROUP BY time_paa_doegnet
ORDER BY time_paa_doegnet ASC;

-- 3. Sammenhæng mellem kilderne
-- En række repræsenterer afhentninger i en samlet bydel (Borough).
SELECT 
    z.Borough AS pickup_bydel,
    COUNT(*) AS antal_afhentninger,
    ROUND(AVG(t.total_amount), 2) AS gns_turpris,
    COUNT(CASE WHEN z.Zone LIKE '%Airport%' THEN 1 END) AS lufthavns_afhentninger
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID
GROUP BY z.Borough
ORDER BY antal_afhentninger DESC;

-- Én række repræsenterer drikkepenge-mønstre for én specifik betalingstype.
SELECT 
    t.payment_type,
    CASE t.payment_type
        WHEN 1 THEN 'Kreditkort'
        WHEN 2 THEN 'Kontant'
        WHEN 3 THEN 'Ingen opkrævning'
        WHEN 4 THEN 'Tvist/Uenighed'
        ELSE 'Andet/Ukendt'
    END AS betalingstype_navn,
    COUNT(*) AS antal_ture,
    ROUND(AVG(t.tip_amount), 2) AS gns_drikkepenge_usd,
    ROUND(AVG(t.tip_amount / NULLIF(t.total_amount, 0)) * 100, 2) AS gns_drikkepenge_procent
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
GROUP BY t.payment_type
ORDER BY t.payment_type ASC;

-- Kontrol 1: Findes der turer med manglende zonematch?
SELECT COUNT(*) AS antal_uden_zonematch
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID
WHERE z.LocationID IS NULL;

-- Kontrol 2: Bliver antallet af rækker mangedoblet af JOIN (Row Explosion Check)?
SELECT 
    (SELECT COUNT(*) FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')) AS raa_turer,
    COUNT(*) AS joinede_turer
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID;