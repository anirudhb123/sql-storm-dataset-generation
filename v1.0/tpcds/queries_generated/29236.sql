
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        c.c_email_address,
        c.c_birth_year,
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low Value'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
benchmark_data AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.cd_gender,
        c.customer_value,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM customer_data c
    LEFT JOIN sales_data sd ON c.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    bd.customer_id,
    bd.full_name,
    bd.cd_gender,
    bd.customer_value,
    bd.total_sales
FROM benchmark_data bd
WHERE 
    (bd.customer_value = 'High Value' AND bd.total_sales > 5000)
    OR (bd.customer_value = 'Medium Value' AND bd.total_sales > 2000)
ORDER BY bd.total_sales DESC, bd.full_name;
