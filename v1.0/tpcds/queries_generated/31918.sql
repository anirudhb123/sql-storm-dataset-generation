
WITH RECURSIVE sales_trend AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, 
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) as sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(ws_sold_date_sk) FROM web_sales) - 30
),
customer_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(d.cd_gender, 'U') AS gender,
           SUM(ws.net_paid) AS total_spent,
           COUNT(ws.ws_order_number) AS total_orders,
           AVG(ws.ws_sales_price) AS avg_order_value
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender
),
store_inventory AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand,
           i.i_product_name, i.i_current_price,
           CASE 
               WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
               ELSE 'In Stock'
           END AS stock_status
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
),
shipping_analysis AS (
    SELECT sm.sm_ship_mode_id, COUNT(ws.ws_order_number) AS num_orders,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)
SELECT cs.c_first_name, cs.c_last_name, cs.gender, 
       st.ws_sold_date_sk, st.ws_quantity, st.ws_sales_price,
       si.i_product_name, si.stock_status, 
       sa.sm_ship_mode_id, sa.num_orders, sa.total_sales, sa.avg_order_value
FROM customer_summary cs
JOIN sales_trend st ON cs.c_customer_sk = st.ws_item_sk
JOIN store_inventory si ON si.inv_item_sk = st.ws_item_sk
LEFT JOIN shipping_analysis sa ON sa.num_orders > 0
WHERE cs.total_spent > 500 AND cs.gender = 'M'
ORDER BY cs.total_spent DESC, st.ws_sold_date_sk DESC
LIMIT 100;
