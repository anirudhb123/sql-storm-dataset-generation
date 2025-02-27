
WITH processed_addresses AS (
    SELECT 
        DISTINCT ca_city, 
        UPPER(ca_street_name) AS upper_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        TRIM(ca_country) AS country
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_country IS NOT NULL
),
address_summary AS (
    SELECT 
        ca_city, 
        COUNT(*) AS total_addresses,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(city_length) AS avg_city_length,
        MIN(full_address) AS min_address,
        MAX(full_address) AS max_address
    FROM processed_addresses
    GROUP BY ca_city
)
SELECT 
    a.ca_city, 
    a.total_addresses, 
    a.avg_street_name_length, 
    a.avg_city_length,
    a.min_address,
    a.max_address,
    c.cd_gender,
    COUNT(c.c_customer_sk) AS customer_count
FROM address_summary a
JOIN customer c ON a.ca_city = 
    (SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    a.ca_city, 
    a.total_addresses, 
    a.avg_street_name_length, 
    a.avg_city_length, 
    a.min_address, 
    a.max_address,
    c.cd_gender
ORDER BY a.total_addresses DESC, a.ca_city
LIMIT 50;
