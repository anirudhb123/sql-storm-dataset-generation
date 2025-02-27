
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_street_address,
        ca_city,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM 
        customer_address
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
date_info AS (
    SELECT 
        d_date_sk,
        d_date,
        CONCAT(DATE_FORMAT(d_date, '%Y-%m-%d'), ' is ', CASE WHEN d_dow IN (1, 7) THEN 'a weekend' ELSE 'a weekday' END) AS date_description
    FROM 
        date_dim
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_street_address,
        ci.date_description,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c 
    JOIN processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_info ci ON c.c_first_shipto_date_sk = ci.d_date_sk
)
SELECT 
    full_name,
    full_street_address,
    date_description,
    cd_gender,
    cd_marital_status
FROM 
    customer_data
WHERE 
    cd_gender = 'F'
ORDER BY 
    full_name;
