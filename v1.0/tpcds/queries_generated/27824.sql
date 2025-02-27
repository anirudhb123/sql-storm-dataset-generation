
WITH StringAggregation AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(DISTINCT c.c_customer_sk) OVER () AS total_customers,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(c.c_email_address FROM 1 FOR 10) AS email_prefix,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_first_name, c.c_last_name, c.c_email_address
)
SELECT 
    full_name,
    total_customers,
    first_name_length,
    last_name_length,
    full_name_length,
    email_prefix,
    cities,
    CASE 
        WHEN first_name_length > 5 THEN 'Long First Name'
        ELSE 'Short First Name'
    END AS first_name_category
FROM 
    StringAggregation
ORDER BY 
    full_name_length DESC;
