
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_country, 
           0 AS level, CAST(c_first_name AS VARCHAR(100)) AS hierarchy_path
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_birth_country,
           ch.level + 1, CONCAT(ch.hierarchy_path, ' -> ', c.c_first_name)
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
inventory_summary AS (
    SELECT inv.warehouse_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.warehouse_sk
),
ship_modes AS (
    SELECT sm.sm_ship_mode_id, sm.sm_type, COUNT(ws.ws_order_number) AS order_count
    FROM ship_mode sm
    LEFT JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
recent_returns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT d_date_sk 
                                   FROM date_dim 
                                   WHERE d_date = CURRENT_DATE)
    GROUP BY sr_item_sk
),
customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT h.c_customer_sk, h.c_first_name, h.c_last_name, h.c_birth_country, h.level, h.hierarchy_path,
       s.total_sales, i.total_quantity, r.total_returns, sm.order_count
FROM customer_hierarchy h
LEFT JOIN customer_sales s ON h.c_customer_sk = s.c_customer_sk
LEFT JOIN inventory_summary i ON i.warehouse_sk = (SELECT w.w_warehouse_sk FROM warehouse w LIMIT 1)
LEFT JOIN recent_returns r ON r.sr_item_sk = (SELECT inv.inv_item_sk FROM inventory inv ORDER BY inv.inv_quantity_on_hand DESC LIMIT 1)
LEFT JOIN ship_modes sm ON sm.sm_order_count = (SELECT MIN(order_count) FROM ship_modes)
WHERE h.level = 3
ORDER BY h.hierarchy_path;
