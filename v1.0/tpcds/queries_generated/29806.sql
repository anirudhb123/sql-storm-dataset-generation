
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        UPPER(ca_city) AS city_upper,
        TRIM(ca_state) AS state_trimmed,
        CONCAT(ca_zip, ', ', ca_country) AS zip_country
    FROM 
        customer_address
),
aggregated_data AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        STRING_AGG(DISTINCT city_upper, ', ') AS cities_list,
        STRING_AGG(DISTINCT zip_country, '; ') AS zips_countries
    FROM 
        processed_addresses
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.cities_list,
    a.zips_countries,
    d.d_year AS year,
    COUNT(c.c_customer_sk) AS total_customers
FROM 
    aggregated_data a
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d2.d_date_sk) FROM date_dim d2)
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
GROUP BY 
    a.ca_state, a.total_addresses, a.unique_cities, a.cities_list, a.zips_countries, d.d_year
ORDER BY 
    a.total_addresses DESC, c.c_customer_sk DESC
LIMIT 10;
