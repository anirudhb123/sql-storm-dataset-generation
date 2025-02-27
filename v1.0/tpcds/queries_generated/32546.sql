
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           c_birth_month,
           0 AS level
    FROM customer
    WHERE c_birth_month IS NOT NULL

    UNION ALL

    SELECT c.customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.current_cdemo_sk,
           c.c_birth_month,
           sh.level + 1
    FROM sales_hierarchy sh
    JOIN customer c ON sh.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE sh.level < 5
),
sales_data AS (
    SELECT ws_cdemo_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_cdemo_sk
),
top_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           sd.total_sales,
           ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN sales_data sd ON c.c_customer_sk = sd.customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
)
SELECT th.c_customer_sk,
       th.c_first_name,
       th.c_last_name,
       th.total_sales,
       CASE 
           WHEN th.sales_rank <= 10 THEN 'Top 10 Customer'
           WHEN th.sales_rank <= 50 THEN 'Top 50 Customer'
           ELSE 'Regular Customer' 
       END AS customer_category,
       COUNT(sh.c_customer_sk) FILTER (WHERE sh.c_birth_month = 1) AS jan_birth_count
FROM top_customers th
LEFT JOIN sales_hierarchy sh ON th.c_customer_sk = sh.c_customer_sk
GROUP BY th.c_customer_sk, th.c_first_name, th.c_last_name, th.total_sales, th.sales_rank
ORDER BY th.total_sales DESC
LIMIT 100;
