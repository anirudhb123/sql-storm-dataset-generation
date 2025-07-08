
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_email_address,
           c_birth_country,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT sh.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           c.c_birth_country,
           sh.level + 1
    FROM sales_hierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
    WHERE sh.level < 3
),
total_sales AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid_inc_tax) AS total_net_sales
    FROM store_sales
    GROUP BY ss_customer_sk
),
sales_statistics AS (
    SELECT sh.c_customer_sk,
           sh.c_first_name,
           sh.c_last_name,
           sh.c_email_address,
           sh.c_birth_country,
           COALESCE(ts.total_net_sales, 0) AS total_sales,
           RANK() OVER (ORDER BY COALESCE(ts.total_net_sales, 0) DESC) AS sales_rank
    FROM sales_hierarchy sh
    LEFT JOIN total_sales ts ON sh.c_customer_sk = ts.ss_customer_sk
)
SELECT s.c_first_name,
       s.c_last_name,
       s.c_email_address,
       s.total_sales,
       CASE 
           WHEN s.total_sales > 1000 THEN 'High Value'
           WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM sales_statistics s
WHERE s.sales_rank <= 100
ORDER BY s.total_sales DESC;
