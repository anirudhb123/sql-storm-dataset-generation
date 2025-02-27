
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, ca_country, 
           CASE 
               WHEN ca_city IS NULL THEN 'Unknown'
               ELSE ca_city END AS city_name,
           1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_street_name, a.ca_city, a.ca_state, a.ca_country, 
           CASE 
               WHEN a.ca_city = h.city_name THEN 'Same City'
               ELSE h.city_name 
           END AS city_name,
           h.level + 1
    FROM customer_address a
    JOIN address_hierarchy h ON a.ca_state = h.ca_state AND h.level < 5 
)
SELECT 
    ca_city, 
    COUNT(*) AS total_addresses, 
    MAX(level) as max_level, 
    COUNT(DISTINCT CASE WHEN ca_country IS NULL THEN 'No Country' ELSE ca_country END) AS distinct_countries,
    SUM(CASE WHEN ca_city IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) as city_ratio,
    ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY COUNT(*) DESC) as rn
FROM address_hierarchy
GROUP BY ca_city
HAVING AVG(CASE WHEN city_name = 'Same City' THEN 1 ELSE 0 END) < 0.5
   OR MAX(level) > 3
ORDER BY total_addresses DESC
LIMIT 10
OFFSET (SELECT COUNT(DISTINCT ca_city) FROM address_hierarchy WHERE ca_state IN ('TX', 'NY')) % 5;

SELECT 
    COALESCE(a.ca_city, 'Unknown City') AS location,
    SUM(CASE WHEN t.t_hour BETWEEN 5 AND 11 THEN s.ss_net_paid ELSE 0 END) AS morning_sales,
    SUM(CASE WHEN t.t_hour BETWEEN 12 AND 17 THEN s.ss_net_paid ELSE 0 END) AS afternoon_sales,
    SUM(CASE WHEN t.t_hour BETWEEN 18 AND 21 THEN s.ss_net_paid ELSE 0 END) AS evening_sales,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM store_sales s
JOIN store st ON s.ss_store_sk = st.s_store_sk
JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
LEFT JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
LEFT JOIN address_hierarchy a ON c.c_current_addr_sk = a.ca_address_sk
WHERE t.t_day_num < 30 AND (c.c_birth_month = 12 OR a.ca_state = 'CA')
GROUP BY a.ca_city
HAVING SUM(s.ss_net_paid) > 1000
ORDER BY unique_customers DESC
LIMIT 10;
