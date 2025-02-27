
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT c_customer_sk FROM store_sales WHERE ss_sold_date_sk = 20230101)
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_addr_sk = sh.c_current_addr_sk
    WHERE sh.level < 3
),
daily_sales AS (
    SELECT d.d_date, SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-01-31'
    GROUP BY d.d_date
),
top_items AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold,
           RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20230131
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 50
),
inventory_summary AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT sh.c_first_name || ' ' || sh.c_last_name AS customer_name,
       ds.d_date,
       ds.total_sales,
       ds.total_orders,
       ti.total_quantity_sold,
       COALESCE(isummary.total_quantity_on_hand, 0) AS quantity_on_hand
FROM sales_hierarchy sh
JOIN daily_sales ds ON ds.d_date = '2023-01-01'
LEFT JOIN top_items ti ON ti.ws_item_sk = sh.c_current_addr_sk
LEFT JOIN inventory_summary isummary ON isummary.inv_item_sk = sh.c_current_addr_sk
WHERE sh.level = 1
ORDER BY customer_name, ds.d_date;
