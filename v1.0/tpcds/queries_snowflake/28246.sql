
WITH StringProcessing AS (
    SELECT 
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        LENGTH(CONCAT(c_first_name, c_last_name)) AS total_length,
        CONCAT(SUBSTR(c_last_name, 1, 1), '.') AS short_name,
        UPPER(c_first_name) AS upper_first_name,
        LOWER(c_last_name) AS lower_last_name,
        REPLACE(c_email_address, '@', '[AT]') AS modified_email
    FROM 
        customer
    WHERE 
        c_email_address IS NOT NULL
),
AggregatedResults AS (
    SELECT 
        AVG(total_length) AS avg_string_length,
        COUNT(DISTINCT short_name) AS unique_short_names,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT upper_first_name) AS unique_upper_first_names,
        LISTAGG(upper_first_name, ', ') AS example_upper_first_names
    FROM 
        StringProcessing
    GROUP BY 
        total_length
)
SELECT 
    a.avg_string_length,
    a.unique_short_names,
    a.total_customers,
    a.unique_upper_first_names,
    a.example_upper_first_names
FROM 
    AggregatedResults a;
