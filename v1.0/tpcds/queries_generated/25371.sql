
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS upper_email,
        LOWER(c.c_city) AS lower_city,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        CASE 
            WHEN POSITION('@' IN c.c_email_address) > 0 THEN 
                SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1)
            ELSE 
                'No Domain'
        END AS email_domain,
        REPLACE(c.c_first_name, 'a', '*') AS modified_first_name
    FROM 
        customer c
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
AggregatedData AS (
    SELECT 
        full_name,
        upper_email,
        lower_city,
        SUM(first_name_length) AS total_first_name_length,
        SUM(last_name_length) AS total_last_name_length,
        COUNT(*) AS total_customers
    FROM 
        StringProcessing
    GROUP BY 
        full_name, upper_email, lower_city
)
SELECT 
    CONCAT('Aggregate Data for Customers: ', COUNT(*)) AS summary,
    AVG(total_first_name_length) AS average_first_name_length,
    AVG(total_last_name_length) AS average_last_name_length,
    STRING_AGG(DISTINCT lower_city, ', ') AS unique_cities
FROM 
    AggregatedData;
