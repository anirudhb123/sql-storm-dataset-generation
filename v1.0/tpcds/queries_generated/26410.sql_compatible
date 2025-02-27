
WITH customer_data AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_data AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer_address ca
),
sales_data AS (
    SELECT 
        ws.ws_billed_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_billed_customer_sk
),
combined_data AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        sd.total_sales
    FROM customer_data cd
    JOIN address_data ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_billed_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COALESCE(total_sales, 0) AS total_sales
FROM combined_data
WHERE cd_gender = 'F'
AND cd_purchase_estimate > 100
ORDER BY total_sales DESC
LIMIT 100;
