
WITH RECURSIVE customer_chain AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           d.d_date, 
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT cr.cr_order_number) AS total_returns,
           COUNT(DISTINCT ws.ws_order_number) - COUNT(DISTINCT cr.cr_order_number) AS successful_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
ranked_customers AS (
    SELECT c.*, 
           ROW_NUMBER() OVER (PARTITION BY YEAR(d.d_date) ORDER BY total_sales DESC) AS rank_within_year,
           AVG(total_sales) OVER (PARTITION BY d.d_year) AS avg_sales_per_year
    FROM customer_chain c
)

SELECT rc.c_first_name, rc.c_last_name, rc.total_sales, 
       CASE 
           WHEN rc.total_returns > 0 THEN 'Returns made'
           ELSE 'No returns'
       END AS return_status,
       CASE 
           WHEN rc.successful_orders = 0 THEN 'No orders placed' 
           ELSE 'Orders placed'
       END AS order_status,
       NULLIF(rc.total_sales - rc.avg_sales_per_year, 0) AS deviation_from_avg
FROM ranked_customers rc
WHERE rc.rank_within_year <= 5
      AND (rc.total_sales IS NOT NULL OR rc.total_returns IS NOT NULL)
ORDER BY rc.total_sales DESC;
