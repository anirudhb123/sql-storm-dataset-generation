
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        REPLACE(c.c_email_address, '@', ' [at] ') AS modified_email
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.modified_email,
    COALESCE(ss.total_quantity, 0) AS total_quantity_purchased,
    COALESCE(ss.total_sales, 0) AS total_sales_amount
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
ORDER BY ci.total_quantity_purchased DESC, ci.full_name;
