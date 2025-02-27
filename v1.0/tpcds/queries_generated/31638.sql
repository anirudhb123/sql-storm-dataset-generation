
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_summary AS (
    SELECT ss_customer_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ss_ticket_number) AS total_transactions,
           MAX(ss_sold_date_sk) AS last_purchase_date,
           DENSE_RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_customer_sk
),
date_info AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_week_seq
    FROM date_dim
    WHERE d_year >= 2020
),
inactive_customers AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           MAX(ss_sold_date_sk) AS last_purchase
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING MAX(ss_sold_date_sk) < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT ch.c_customer_sk,
       ch.c_first_name,
       ch.c_last_name,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.total_transactions, 0) AS total_transactions,
       COALESCE(di.d_year, 0) AS year,
       COALESCE(di.d_month_seq, 0) AS month,
       CASE 
           WHEN ic.last_purchase IS NOT NULL THEN 'Inactive'
           ELSE 'Active'
       END AS customer_status
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ss_customer_sk
LEFT JOIN date_info di ON ss.last_purchase_date = di.d_date_sk
LEFT JOIN inactive_customers ic ON ch.c_customer_sk = ic.c_customer_sk
WHERE ss.total_sales > 1000 OR ch.level = 1
ORDER BY customer_status, total_sales DESC;
