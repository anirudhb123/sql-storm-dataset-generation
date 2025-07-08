
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(LOWER(ca_city)) AS normalized_city,
        REPLACE(ca_zip, '-', '') AS clean_zip
    FROM 
        customer_address
),
address_counts AS (
    SELECT 
        normalized_city,
        COUNT(*) AS city_count
    FROM 
        processed_addresses
    GROUP BY 
        normalized_city
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        d.d_date AS registration_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ac.city_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    LEFT JOIN 
        address_counts ac ON ac.normalized_city = TRIM(LOWER((SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)))
)
SELECT 
    customer_name,
    registration_date,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    city_count
FROM 
    customer_info
ORDER BY 
    registration_date DESC,
    customer_name
LIMIT 100;
