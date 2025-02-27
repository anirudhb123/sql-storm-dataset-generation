
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 3
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sales.total_net_profit DESC) AS rn
    FROM sales_summary sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
)
SELECT 
    ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
    COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
    ti.total_quantity,
    ti.total_net_profit
FROM customer_hierarchy ch
LEFT JOIN top_items ti ON ch.c_current_cdemo_sk = ti.total_orders
LEFT JOIN item i ON ti.ws_item_sk = i.i_item_sk
WHERE ti.total_net_profit IS NOT NULL
ORDER BY ch.level, ti.total_net_profit DESC;
