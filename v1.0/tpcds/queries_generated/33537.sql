
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_payment,
        MIN(ws.ws_net_paid_inc_tax) AS min_payment,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS popularity_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT
        item.i_item_sk,
        item.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_profit,
        sd.max_payment,
        sd.min_payment
    FROM item
    JOIN sales_data sd ON item.i_item_sk = sd.ws_item_sk
    WHERE sd.total_quantity > 100
),
address_summary AS (
    SELECT 
        a.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count
    FROM customer_address a
    LEFT JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN warehouse w ON a.ca_state = w.w_state
    GROUP BY a.ca_state
)
SELECT 
    th.i_item_desc,
    th.total_quantity,
    th.total_sales,
    th.avg_profit,
    th.max_payment,
    th.min_payment,
    asu.customer_count,
    asu.warehouse_count
FROM top_sales th
JOIN address_summary asu ON th.i_item_sk % 5 = asu.customer_count % 5
WHERE th.popularity_rank <= 5
ORDER BY th.total_sales DESC;
