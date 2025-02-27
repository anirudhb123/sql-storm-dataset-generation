
WITH StringBenchmark AS (
    SELECT 
        ca_city,
        ca_street_name,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        LENGTH(CONCAT(c_first_name, ' ', c_last_name)) AS full_name_length,
        UPPER(c_first_name) AS upper_first_name,
        LOWER(c_last_name) AS lower_last_name,
        REPLACE(c_email_address, '@example.com', '@benchmark.com') AS modified_email,
        SUBSTRING(c_login FROM 1 FOR 5) AS login_prefix,
        TRIM(c_preferred_cust_flag) AS trimmed_preference
    FROM customer 
    JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
    WHERE 
        ca_city IS NOT NULL 
        AND c_first_name IS NOT NULL 
        AND c_last_name IS NOT NULL
),
AggregatedResults AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_customers,
        AVG(full_name_length) AS avg_full_name_length,
        COUNT(DISTINCT login_prefix) AS unique_login_prefix_count,
        STRING_AGG(DISTINCT upper_first_name, ', ') AS all_upper_first_names,
        STRING_AGG(DISTINCT lower_last_name, ', ') AS all_lower_last_names
    FROM StringBenchmark
    GROUP BY ca_city
)
SELECT 
    ca_city,
    total_customers,
    avg_full_name_length,
    unique_login_prefix_count,
    all_upper_first_names,
    all_lower_last_names
FROM AggregatedResults
ORDER BY total_customers DESC
LIMIT 10;
