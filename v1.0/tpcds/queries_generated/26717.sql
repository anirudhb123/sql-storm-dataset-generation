
WITH String_Benchmark AS (
    SELECT 
        ca_street_name,
        ca_city,
        CONCAT(ca_street_name, ', ', ca_city) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS upper_case_street_name,
        LOWER(ca_city) AS lower_case_city,
        REPLACE(ca_street_name, 'Street', 'St.') AS abbreviated_street_name,
        SUBSTRING(ca_city, 1, 3) AS city_prefix
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
Address_Analysis AS (
    SELECT 
        COUNT(*) AS total_addresses,
        AVG(street_name_length) AS avg_street_name_length,
        COUNT(DISTINCT full_address) AS unique_full_addresses,
        STRING_AGG(DISTINCT city_prefix, ', ') AS city_prefixes
    FROM 
        String_Benchmark
)
SELECT 
    a.total_addresses,
    a.avg_street_name_length,
    a.unique_full_addresses,
    a.city_prefixes,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers
FROM 
    Address_Analysis a
JOIN 
    customer c ON c.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'Los Angeles' LIMIT 1)
GROUP BY 
    a.total_addresses, a.avg_street_name_length, a.unique_full_addresses, a.city_prefixes;
