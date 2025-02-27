
WITH RECURSIVE customer_purchases AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, w.w_warehouse_id,
           ws.ws_order_number, ws.ws_ext_sales_price, ws.ws_sales_price,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk) AS purchase_rank
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_sales_price > 0
),
eligible_customers AS (
    SELECT cp.c_customer_sk, cp.c_first_name, cp.c_last_name
    FROM customer_purchases AS cp
    GROUP BY cp.c_customer_sk, cp.c_first_name, cp.c_last_name
    HAVING COUNT(cp.ws_order_number) >= 5
),
customer_stats AS (
    SELECT e.c_customer_sk, e.c_first_name, e.c_last_name,
           SUM(cp.ws_ext_sales_price) AS total_spent,
           AVG(cp.ws_sales_price) AS avg_purchase_price
    FROM eligible_customers AS e
    LEFT JOIN customer_purchases AS cp ON e.c_customer_sk = cp.c_customer_sk
    GROUP BY e.c_customer_sk, e.c_first_name, e.c_last_name
)
SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name,
       cs.total_spent, cs.avg_purchase_price,
       CASE 
           WHEN cs.total_spent IS NOT NULL THEN 'Active'
           ELSE 'Inactive'
       END AS customer_status,
       COALESCE((SELECT MAX(ws.ws_net_profit) 
                 FROM web_sales AS ws 
                 WHERE ws.ws_bill_customer_sk = cs.c_customer_sk), 0) AS max_net_profit,
       (SELECT COUNT(DISTINCT ws.ws_order_number) 
        FROM web_sales AS ws 
        WHERE ws.ws_bill_customer_sk = cs.c_customer_sk) AS total_orders,
       (SELECT COUNT(*)
        FROM customer_address AS ca
        WHERE ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer AS c WHERE c.c_customer_sk = cs.c_customer_sk)
        AND ca.ca_city IS NOT NULL) AS valid_address_count
FROM customer_stats AS cs
ORDER BY cs.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
