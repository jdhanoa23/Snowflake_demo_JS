// Previewing the data
/*
The first top 10 rows from the IP geolocation demo database.
*/
SELECT *
FROM demo.location
LIMIT 10;
;

// Get Specific IP address data
/*
Use this query if you want to get geolocation information of a single IP address. Replace the IP address provided with your desired IP address.
*/
-- '123.175.99.95' ⇒ Input IP Address

SELECT *
FROM demo.location
WHERE public.TO_INT('123.175.99.95') 
      BETWEEN start_ip_int AND end_ip_int;

-----------------
-- Explanation --
-----------------

-- TO_INT is a custom function that converts IP address values to their integer equivalent
-- start_ip_int represents the integer equivalent of the start_ip column
-- end_ip_int represents that integer equivalent of the end_ip column
-- The BETWEEN function checks to see if your input IP address falls between an the IP Range of start_ip_int and end_ip_int;

// Get the number of IP addresses by City (Groupby - Count)
/*
Get the number of IP addresses located in each city.
*/
SELECT 
  COUNT(start_ip) AS num_ips,
  city
FROM demo.location
GROUP BY city
ORDER BY num_ips DESC;
;

// Specific data query from IP address lookup
/*
Extract specific geolocation details such as, city, region, country, geographic coordinates (latitude & longitude) and timezone from a single IP address lookup.
*/
-- Input IP Address: '63.42.63.129'

SELECT 
  city,
  region,
  country,
  lat AS latitude,
  lng AS longitude,
  postal,
  timezone
FROM demo.location
WHERE public.TO_INT('63.42.63.129') 
      BETWEEN start_ip_int AND end_ip_int;
;

// Optimized join on IP Addresses
/*
Joining a table that has IP addresses to IPinfo’s geolocation table. This join operation uses the Join Key column to facilitate the join operation, creating a joined table that contains the input IP address and IPinfo’s geolocation insights.
*/
-- Placeholder CTE representing the log database that contains IP addresses
-- Contains two IP addresses in the 'ip' column
WITH log AS (
    SELECT '172.4.12.1' AS ip
    UNION 
    SELECT '172.4.12.2'
)

-- Query to join the log database with the IPinfo geolocation database
SELECT
  input_db.ip,
  loc.city,
  loc.region,
  loc.country,
  loc.postal,
  loc.lat,
  loc.lng,
  loc.timezone
FROM log AS input_db
JOIN demo.location AS loc
  ON public.TO_JOIN_KEY(input_db.ip) = loc.join_key
  AND public.TO_INT(input_db.ip) BETWEEN loc.start_ip_int AND loc.end_ip_int;

-----------------
-- Explanation --
-----------------

-- 1. The `log` Common Table Expression (CTE) serves as a placeholder table containing two IP addresses.
-- 2. The `demo.location` table contains geolocation data for ranges of IPs, including city, region, and other details.
-- 3. The `JOIN` operation matches IP addresses from the `log` table to the appropriate IP range in `demo.location`:
--     a. `public.TO_JOIN_KEY(input_db.ip)` transforms the IP into a join key to match with `loc.join_key`.
--     b. The `BETWEEN` condition ensures the IP falls within the appropriate range (`start_ip_int` to `end_ip_int`).
-- 4. The final result includes the `ip` from the `log` table and its corresponding geolocation details from `demo.location`.
;

// Top 10 Nearest IP Address from a location
/*
The Nearest IP address shows the closest IP addresses from a geographic coordinate. We use the “Haversine formula” to find IP addresses from the provided Latitude and Longitude values.
*/
-- Input Latitude and Longitude
-- Latitude: 42.556
-- Longitude: -87.8705

SELECT
  HAVERSINE(42.556, -87.8705, lat, lng) AS distance,
  start_ip,
  end_ip,
  city,
  region,
  country,
  postal,
  timezone
FROM demo.location
ORDER BY distance ASC
LIMIT 10;

-----------------
-- Explanation --
-----------------

-- 1. Haversine Formula: Calculates the great-circle distance between two points on Earth based on latitude and longitude.
--    Reference: https://en.wikipedia.org/wiki/Haversine_formula
-- 2. Inputs: Latitude (42.556) and Longitude (-87.8705) are the reference point for distance calculations.
-- 3. Columns:
--    - distance: Computed distance from the input coordinates to the geolocation coordinates (lat, lng) in demo.location.
--    - Geolocation data (city, region, etc.) describes the nearest IP ranges.
-- 4. Ordering and Limiting:
--    - Results are sorted by distance in ascending order to list the closest IP ranges first.
--    - Limited to the top 10 results for simplicity and efficiency.
;

