
WITH address_details AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
customer_info AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_birth_month || '/' || cd_birth_day || '/' || cd_birth_year AS birth_date,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    ci.full_name,
    ai.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.birth_date,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM customer_info ci
JOIN address_details ai ON ci.c_customer_sk = ai.ca_address_sk
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE ci.cd_purchase_estimate > 1000
ORDER BY ci.total_sales DESC
LIMIT 10;
