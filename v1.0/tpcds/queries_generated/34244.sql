
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk,
           i_item_id,
           i_item_desc,
           i_current_price,
           i_brand,
           i_class
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)

    UNION ALL

    SELECT i.i_item_sk,
           i.i_item_id,
           CONCAT(ih.i_item_desc, ' > ', i.i_item_desc),
           i.i_current_price,
           i.i_brand,
           i.i_class
    FROM item i
    INNER JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
customer_stats AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(DISTINCT CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_order_number END) AS catalog_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT cs.c_customer_sk,
           cs.total_orders,
           cs.total_spent,
           RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM customer_stats cs
    WHERE cs.total_spent IS NOT NULL
),
recent_item_sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY ws.ws_item_sk
),
shipment_analysis AS (
    SELECT sm.sm_ship_mode_id,
           COUNT(ws.ws_order_number) AS total_shipments,
           SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
           AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)
SELECT ci.i_item_id,
       ci.i_item_desc,
       ci.i_current_price,
       tc.c_customer_sk,
       tc.total_orders,
       tc.total_spent,
       wh.w_warehouse_id,
       sa.sm_ship_mode_id,
       sa.total_shipments,
       sa.total_ship_cost,
       h.hd_income_band_sk,
       dia.total_quantity_sold,
       dia.total_revenue,
       RANK() OVER (PARTITION BY a.hd_income_band_sk ORDER BY dia.total_revenue DESC) AS item_rank
FROM item_hierarchy ci
LEFT JOIN top_customers tc ON ci.i_item_sk = tc.c_customer_sk
LEFT JOIN recent_item_sales dia ON ci.i_item_sk = dia.ws_item_sk
LEFT JOIN shipment_analysis sa ON sa.sm_ship_mode_id = ci.i_item_sk
LEFT JOIN household_demographics h ON h.hd_demo_sk = tc.c_customer_sk
LEFT JOIN warehouse wh ON wh.w_warehouse_sk = ci.i_item_sk
WHERE ci.i_current_price > 0
  AND tc.spending_rank <= 10
  AND dia.total_quantity_sold IS NOT NULL 
ORDER BY dia.total_revenue DESC;
