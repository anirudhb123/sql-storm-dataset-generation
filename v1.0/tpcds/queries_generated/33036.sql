
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales 
    WHERE ws_ship_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_ship_customer_sk
),
customer_info AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN web_sales ON ws_ship_customer_sk = c_customer_sk
    GROUP BY c_customer_id, c_first_name, c_last_name, cd_gender, cd_marital_status, cd_credit_rating
),
address_info AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ca_zip
    FROM customer_address
),
combined_data AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.total_spent,
        ai.ca_city,
        ai.ca_state,
        ai.ca_country,
        ai.ca_zip,
        ss.total_profit,
        ss.order_count,
        ss.rank
    FROM customer_info ci
    LEFT JOIN address_info ai ON ai.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_id = ci.c_customer_id)
    LEFT JOIN sales_summary ss ON ss.ws_ship_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = ci.c_customer_id)
)
SELECT * 
FROM combined_data
WHERE total_spent IS NOT NULL
AND (cd_gender = 'M' OR cd_marital_status = 'S')
ORDER BY total_spent DESC
LIMIT 10;
