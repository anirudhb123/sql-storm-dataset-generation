
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           d.d_date_id, ws.ws_order_number, ws.ws_sales_price,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) as sale_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    AND d.d_year = 2022
    UNION ALL
    SELECT src.c_customer_sk, src.c_first_name, src.c_last_name, 
           d.d_date_id, wr.wr_order_number, wr.wr_return_amt,
           ROW_NUMBER() OVER (PARTITION BY src.c_customer_sk ORDER BY d.d_date) as sale_rank
    FROM customer src
    JOIN web_returns wr ON src.c_customer_sk = wr.w_returning_customer_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE src.c_birth_year BETWEEN 1970 AND 1990
    AND d.d_year = 2022
),
aggregated_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COUNT(DISTINCT ws.ws_order_number) as total_orders,
           SUM(ws.ws_sales_price) as total_spent,
           SUM(wr.wr_return_amt) as total_returned
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT a.c_customer_sk, a.c_first_name, a.c_last_name,
       a.total_orders, a.total_spent, a.total_returned,
       (a.total_spent - COALESCE(a.total_returned, 0)) AS net_spent,
       CASE 
           WHEN a.total_orders = 0 THEN 'No Orders'
           WHEN a.total_orders < 5 THEN 'Few Orders'
           ELSE 'Frequent Customer'
       END AS customer_status
FROM aggregated_sales a
WHERE a.total_spent > 0
ORDER BY net_spent DESC
FETCH FIRST 10 ROWS ONLY;
