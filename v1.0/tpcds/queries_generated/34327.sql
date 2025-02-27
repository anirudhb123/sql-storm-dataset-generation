
WITH RECURSIVE top_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    HAVING SUM(ws_ext_sales_price) > 10000
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) 
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN top_customers tc ON c.c_customer_sk != tc.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
customer_returns AS (
    SELECT cr_returning_customer_sk, 
           SUM(cr_return_amount) AS total_return_amount,
           COUNT(cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr_returning_customer_sk
), 
store_sales_summary AS (
    SELECT s.c_customer_sk, 
           SUM(ss_ext_sales_price) AS total_sales,
           SUM(ss_ext_sales_price) - COALESCE(SUM(cr_return_amount), 0) AS net_sales
    FROM store_sales ss
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY s.c_customer_sk
)
SELECT c.c_first_name, c.c_last_name, 
       COALESCE(ss.total_sales, 0) AS total_sales, 
       COALESCE(ss.net_sales, 0) AS net_sales,
       CASE 
           WHEN ss.total_sales IS NOT NULL THEN 'Customer with Sales'
           ELSE 'No Sales'
       END AS sales_status
FROM customer c
LEFT JOIN store_sales_summary ss ON c.c_customer_sk = ss.c_customer_sk
WHERE c.c_birth_month = 7 
  AND (c.c_preferred_cust_flag = 'Y' OR ss.net_sales > 5000)
ORDER BY total_sales DESC
LIMIT 10;
