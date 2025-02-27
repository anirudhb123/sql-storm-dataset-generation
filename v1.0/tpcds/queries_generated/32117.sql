
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        ds_item_sk,
        total_quantity,
        total_profit
    FROM sales_data
    WHERE rn = 1
)
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ti.total_quantity) AS total_item_quantity,
    AVG(ti.total_profit) AS average_profit,
    MAX(ti.total_profit) AS max_profit,
    MIN(ti.total_profit) AS min_profit
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN top_items ti ON c.c_customer_sk = ti.ws_item_sk
JOIN (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY d_year, d_month_seq
) orders ON true
WHERE ca.ca_state IS NOT NULL
GROUP BY ca_state
ORDER BY unique_customers DESC
LIMIT 10
OFFSET 5;
