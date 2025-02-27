
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           COALESCE(ss_ext_sales_price, 0) AS total_sales
    FROM customer 
    LEFT JOIN store_sales ON c_customer_sk = ss_customer_sk
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(s.total_sales, 0) + s.ss_ext_sales_price
    FROM sales_hierarchy s
    JOIN customer c ON c.c_customer_sk = s.c_customer_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    WHERE s.total_sales < 10000
), 
monthly_sales AS (
    SELECT d_month_seq, SUM(ws_ext_sales_price) AS total_monthly_sales
    FROM web_sales 
    JOIN date_dim ON date_dim.d_date_sk = web_sales.ws_sold_date_sk
    GROUP BY d_month_seq
), 
average_sales AS (
    SELECT AVG(total_monthly_sales) AS avg_sales
    FROM monthly_sales
), 
top_customers AS (
    SELECT c_first_name, c_last_name, 
           SUM(ws_ext_sales_price) AS total_sales
    FROM customer 
    JOIN web_sales ON customer.c_customer_sk = web_sales.ws_ship_customer_sk
    GROUP BY c_first_name, c_last_name
    HAVING SUM(ws_ext_sales_price) > (SELECT avg_sales FROM average_sales)
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_first_name, tc.c_last_name, 
    COALESCE(th.total_sales, 0) AS hierarchy_sales,
    (SELECT SUM(total_sales) FROM sales_hierarchy WHERE c_customer_sk = tc.c_customer_sk) AS recursive_sales,
    CASE WHEN th.total_sales IS NULL THEN 'No Sales' ELSE 'Has Sales' END AS sales_status
FROM top_customers tc
LEFT JOIN (
    SELECT c_customer_sk, SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    GROUP BY c_customer_sk
) th ON tc.c_customer_sk = th.c_customer_sk
ORDER BY hierarchy_sales DESC;
