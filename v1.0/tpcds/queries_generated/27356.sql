
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        cd_purchase_estimate,
        ca_country
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ci.c_customer_sk,
    ci.full_name,
    ci.gender,
    ci.marital_status,
    ci.full_address,
    ci.cd_purchase_estimate,
    ci.ca_country,
    sd.total_sales,
    sd.order_count
FROM
    customer_info ci
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE
    ci.cd_purchase_estimate > 500
ORDER BY 
    total_sales DESC
LIMIT 100;
