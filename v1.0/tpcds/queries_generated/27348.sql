
WITH string_benchmark AS (
    SELECT 
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        UPPER(c.c_first_name) AS first_name_upper,
        LOWER(c.c_last_name) AS last_name_lower,
        TRIM(c.c_first_name) AS first_name_trimmed,
        REPLACE(c.c_last_name, 'a', '@') AS last_name_replaced,
        LPAD(CAST(c.c_customer_sk AS char), 10, '0') AS padded_customer_id,
        c.c_email_address,
        CHAR_LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    WHERE 
        c.c_email_address IS NOT NULL
),
string_statistics AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(full_name_length) AS average_full_name_length,
        MIN(full_name_length) AS min_full_name_length,
        MAX(full_name_length) AS max_full_name_length,
        COUNT(DISTINCT first_name_upper) AS unique_first_names,
        COUNT(DISTINCT last_name_lower) AS unique_last_names
    FROM 
        string_benchmark
)
SELECT 
    *,
    CONCAT('Total Customers: ', total_customers) AS total_customers_summary,
    CONCAT('Avg Full Name Length: ', ROUND(average_full_name_length, 2)) AS average_full_name_length_summary,
    CONCAT('Min Full Name Length: ', min_full_name_length) AS min_full_name_length_summary,
    CONCAT('Max Full Name Length: ', max_full_name_length) AS max_full_name_length_summary,
    CONCAT('Unique First Names: ', unique_first_names) AS unique_first_names_summary,
    CONCAT('Unique Last Names: ', unique_last_names) AS unique_last_names_summary
FROM 
    string_statistics;
