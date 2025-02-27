
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ',
            TRIM(ca_street_name), ' ',
            TRIM(ca_street_type), 
            CASE 
                WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', TRIM(ca_suite_number)) 
                ELSE ''
            END,
            ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)
        ) AS full_address
    FROM customer_address
),
distinct_customers AS (
    SELECT 
        DISTINCT c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        da.full_address
    FROM customer c
    JOIN processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
    WHERE c.c_birth_year >= 1980 
    AND c.c_birth_country = 'USA'
),
count_per_state AS (
    SELECT 
        da.full_address,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUBSTRING_INDEX(da.full_address, ',', -1) AS state
    FROM distinct_customers c
    JOIN processed_addresses da ON c.full_address = da.full_address
    GROUP BY state
)
SELECT 
    state,
    customer_count,
    RANK() OVER (ORDER BY customer_count DESC) AS rank
FROM count_per_state
WHERE customer_count > 0
ORDER BY customer_count DESC;
