
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_data AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
    WHERE ca.ca_state IS NOT NULL AND ca.ca_city IS NOT NULL
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_order_number
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    sd.total_quantity,
    sd.total_sales
FROM customer_data cd
JOIN address_data ad ON cd.c_customer_id = ad.ca_address_id
LEFT JOIN sales_data sd ON cd.c_customer_id = sd.ws_order_number
WHERE cd.purchase_estimate > 1000 AND ad.ca_country = 'USA'
ORDER BY cd.full_name, sd.total_sales DESC;
