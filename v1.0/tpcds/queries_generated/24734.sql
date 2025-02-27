
WITH RECURSIVE sales_ranking AS (
    SELECT ss.sold_date_sk, 
           ss.store_sk, 
           ss.item_sk, 
           SUM(ss.ss_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    INNER JOIN date_dim dd ON ss.sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ss.sold_date_sk, ss.store_sk, ss.item_sk
),
customer_activity AS (
    SELECT c.c_customer_id,
           COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
           SUM(ws.ws_net_paid) AS total_spent,
           (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS total_web_returns
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT ca.c_customer_id,
           ca.total_web_orders,
           ca.total_spent,
           ca.total_web_returns,
           CASE WHEN ca.total_spent IS NULL THEN 'UNKNOWN'
                WHEN ca.total_spent > 1000 THEN 'HIGH VALUE'
                ELSE 'LOW VALUE' END AS customer_segment
    FROM customer_activity ca
)
SELECT s.store_sk, 
       s.sold_date_sk,
       sr.total_profit,
       COALESCE(hv.total_web_orders, 0) AS total_web_orders,
       COALESCE(hv.total_spent, 0) AS total_spent,
       COUNT(DISTINCT hv.c_customer_id) AS unique_high_value_customers,
       SUM(CASE WHEN hv.customer_segment = 'HIGH VALUE' THEN 1 ELSE 0 END) AS high_value_count,
       AVG(cl.c_demo_sk) AS avg_demo_sk
FROM store_sales s
LEFT JOIN sales_ranking sr ON s.store_sk = sr.store_sk AND s.sold_date_sk = sr.sold_date_sk
LEFT JOIN high_value_customers hv ON hv.total_spent > 1000
LEFT JOIN customer_demographics cl ON cl.cd_demo_sk = hv.c_customer_id  
GROUP BY s.store_sk, s.sold_date_sk, sr.total_profit
HAVING SUM(s.ss_net_profit) > 0
ORDER BY s.store_sk, s.sold_date_sk DESC
OPTION (MAXDOP 4);
