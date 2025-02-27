
WITH RECURSIVE recent_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
    FROM customer c
    JOIN recent_customers rc ON c.c_current_cdemo_sk = rc.c_current_cdemo_sk
    WHERE c.c_customer_sk <> rc.c_customer_sk
),
customer_stats AS (
    SELECT cd.cd_demo_sk, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_value,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY cd.cd_demo_sk
),
item_performance AS (
    SELECT i.i_item_sk, 
           i.i_item_desc,
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_ship_date_sk BETWEEN 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '1 MONTH') 
          AND CURRENT_DATE
    GROUP BY i.i_item_sk, i.i_item_desc
),
shipping_stats AS (
    SELECT sm.sm_ship_mode_id, 
           COUNT(DISTINCT ws.ws_order_number) AS orders_count,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(ws.ws_ext_ship_cost) AS avg_shipping_cost
    FROM sm_ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)

SELECT rc.c_first_name || ' ' || rc.c_last_name AS customer_name,
       cs.customer_count,
       cs.returns_count,
       cs.total_return_value,
       ip.total_sold,
       ip.total_sales,
       ss.orders_count AS total_shipping_orders,
       ss.total_profit,
       ss.avg_shipping_cost
FROM recent_customers rc
JOIN customer_stats cs ON rc.c_current_cdemo_sk = cs.cd_demo_sk
LEFT JOIN item_performance ip ON ip.total_sold > 0
LEFT JOIN shipping_stats ss ON ss.orders_count > 0
WHERE cs.avg_purchase_estimate > 200 AND cs.total_return_value > 1000
ORDER BY cs.total_return_value DESC
LIMIT 100;
