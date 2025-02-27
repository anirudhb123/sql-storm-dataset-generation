
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk, 
        ws.item_sk, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS sales_rank,
        SUM(ws.net_profit) OVER (PARTITION BY ws.bill_customer_sk) AS total_profit
    FROM web_sales ws
    WHERE ws.ship_date_sk > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        r.total_profit,
        r.item_sk,
        r.sales_rank
    FROM ranked_sales r
    JOIN customer_info ci ON r.bill_customer_sk = ci.c_customer_sk
    WHERE r.sales_rank = 1 AND r.total_profit > 1000
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.cd_purchase_estimate,
    ss.total_profit,
    coalesce(i.i_product_name, 'Unknown Product') AS best_selling_product
FROM sales_summary ss
LEFT JOIN item i ON ss.item_sk = i.i_item_sk
WHERE ss.cd_marital_status IN ('M', 'S')
ORDER BY ss.total_profit DESC, ss.c_last_name, ss.c_first_name;
