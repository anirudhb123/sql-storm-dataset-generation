
WITH string_benchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_case_name,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS upper_case_name,
        LPAD(c.ca_address_id, 20, '0') AS padded_address_id,
        SUBSTRING(c.c_email_address, 1, 10) AS email_prefix,
        REPLACE(c.c_email_address, '@', '[at]') AS email_with_placeholder
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_customer_sk % 1000 = 0
),
aggregate_results AS (
    SELECT
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT lower_case_name) AS unique_lower_case_names,
        COUNT(DISTINCT upper_case_name) AS unique_upper_case_names,
        COUNT(DISTINCT padded_address_id) AS unique_padded_address_ids,
        COUNT(DISTINCT email_prefix) AS unique_email_prefixes,
        COUNT(DISTINCT email_with_placeholder) AS unique_email_placeholder_count
    FROM string_benchmark
)

SELECT
    *,
    CASE 
        WHEN avg_name_length > 30 THEN 'Long Names'
        WHEN avg_name_length BETWEEN 20 AND 30 THEN 'Medium Names'
        ELSE 'Short Names'
    END AS name_category
FROM aggregate_results;
