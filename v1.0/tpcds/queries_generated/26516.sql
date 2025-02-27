
WITH processed_strings AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(LOWER(c.c_email_address), '@', '[at]') AS email_processed,
        TRIM(w.w_warehouse_name) AS warehouse_name,
        COALESCE(SUBSTRING(c.c_birth_country, 1, 3), 'N/A') AS birth_country_short,
        LENGTH(REPLACE(REPLACE(c.c_first_name, ' ', ''), '-', '')) AS first_name_length
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        warehouse w ON ca.ca_address_sk = w.w_warehouse_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
),
aggregated_data AS (
    SELECT 
        full_name,
        COUNT(DISTINCT email_processed) AS unique_email_count,
        COUNT(DISTINCT warehouse_name) AS unique_warehouses,
        AVG(first_name_length) AS avg_first_name_length,
        STRING_AGG(birth_country_short, ', ') AS country_short_list
    FROM 
        processed_strings
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    unique_email_count,
    unique_warehouses,
    avg_first_name_length,
    country_short_list
FROM 
    aggregated_data
ORDER BY 
    avg_first_name_length DESC
LIMIT 100;
