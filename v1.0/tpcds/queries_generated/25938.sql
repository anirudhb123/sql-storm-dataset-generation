
WITH processed_customer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(cd.education_status, 'Unknown') AS education,
        COALESCE(cd.credit_rating, 'No Rating') AS credit_rating,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
benchmark AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(LENGTH(full_name)) AS avg_name_length,
        COUNT(DISTINCT ca_city) AS distinct_cities,
        COUNT(DISTINCT ca_state) AS distinct_states,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length
    FROM 
        processed_customer
)
SELECT 
    total_customers,
    avg_name_length,
    distinct_cities,
    distinct_states,
    max_address_length,
    min_address_length
FROM 
    benchmark;
