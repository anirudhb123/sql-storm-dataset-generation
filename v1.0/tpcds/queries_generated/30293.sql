
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_bs.bill_customer_sk,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bs.bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    INNER JOIN customer ws_bs ON ws.ws_bill_customer_sk = ws_bs.c_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2023-01-01')
),
customer_performance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS total_items_sold,
        COALESCE(MAX(ws.ws_net_paid_inc_tax), 0) AS highest_order_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
aggregate_performance AS (
    SELECT
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.total_net_profit,
        cp.total_orders,
        cp.total_items_sold,
        cp.highest_order_value,
        CASE 
            WHEN cp.total_net_profit > 10000 THEN 'High Value'
            WHEN cp.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_segment
    FROM customer_performance cp
)
SELECT 
    ap.c_customer_sk,
    ap.c_first_name,
    ap.c_last_name,
    ap.cd_gender,
    ap.total_net_profit,
    ap.total_orders,
    ap.total_items_sold,
    ap.highest_order_value,
    ROW_NUMBER() OVER (ORDER BY ap.total_net_profit DESC) AS rank
FROM aggregate_performance ap
WHERE ap.total_orders > 5
ORDER BY ap.total_net_profit DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
