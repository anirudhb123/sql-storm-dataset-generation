
WITH StringData AS (
    SELECT 
        c.c_first_name AS customer_first_name,
        c.c_last_name AS customer_last_name,
        ca.ca_city AS address_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS name_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        REPLACE(UPPER(CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip)), ' ', '_') AS formatted_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
AggregatedData AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(name_length) AS avg_name_length,
        LISTAGG(DISTINCT upper_first_name, ', ') WITHIN GROUP (ORDER BY upper_first_name) AS unique_upper_first_names,
        LISTAGG(DISTINCT lower_last_name, ', ') WITHIN GROUP (ORDER BY lower_last_name) AS unique_lower_last_names,
        LISTAGG(DISTINCT formatted_address, ', ') WITHIN GROUP (ORDER BY formatted_address) AS unique_addresses
    FROM 
        StringData
)
SELECT 
    total_customers,
    avg_name_length,
    unique_upper_first_names,
    unique_lower_last_names,
    unique_addresses
FROM 
    AggregatedData;
