
WITH customer_info AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           ca.ca_city,
           ca.ca_state,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           i.i_brand,
           i.i_category,
           i.i_current_price
    FROM item i
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
benchmark_data AS (
    SELECT ci.full_name,
           ci.ca_city,
           ci.ca_state,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           si.i_item_desc,
           si.i_brand,
           si.i_category,
           sd.total_profit,
           sd.total_orders
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    JOIN item_info si ON si.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk)
)
SELECT CONCAT(LEFT(full_name, 20), '...') AS truncated_name,
       ca_city,
       ca_state,
       cd_gender,
       cd_marital_status,
       cd_education_status,
       i_item_desc,
       i_brand,
       i_category,
       ROUND(total_profit, 2) AS formatted_profit,
       total_orders
FROM benchmark_data
WHERE ca_city IS NOT NULL
ORDER BY total_profit DESC, total_orders DESC
LIMIT 100;
