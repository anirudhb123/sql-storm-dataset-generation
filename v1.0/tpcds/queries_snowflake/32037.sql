
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COUNT(rs.ss_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN store_sales rs ON c.c_customer_sk = rs.ss_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           sh.total_sales + COUNT(rs.ss_sales_price)
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    LEFT JOIN store_sales rs ON c.c_customer_sk = rs.ss_customer_sk
    WHERE c.c_birth_year < 1980
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales
),
sales_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
           SUM(COALESCE(ss.total_sales, 0)) AS total_store_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN sales_hierarchy ss ON c.c_customer_sk = ss.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
joined_sales AS (
    SELECT ss.c_customer_sk, ss.c_first_name, ss.c_last_name, 
           ss.total_web_sales, ss.total_store_sales,
           CASE 
               WHEN ss.total_web_sales > 0 AND ss.total_store_sales > 0 THEN 'Both'
               WHEN ss.total_web_sales > 0 THEN 'Web Only'
               WHEN ss.total_store_sales > 0 THEN 'Store Only'
               ELSE 'No Sales'
           END AS sales_mode
    FROM sales_summary ss
),
ranked_sales AS (
    SELECT js.*, 
           RANK() OVER (PARTITION BY js.sales_mode ORDER BY (js.total_web_sales + js.total_store_sales) DESC) AS sales_rank
    FROM joined_sales js
)
SELECT r.c_customer_sk, r.c_first_name, r.c_last_name, r.total_web_sales, r.total_store_sales, 
       r.sales_mode, r.sales_rank
FROM ranked_sales r
WHERE r.sales_rank <= 10
ORDER BY r.sales_mode, r.sales_rank;
