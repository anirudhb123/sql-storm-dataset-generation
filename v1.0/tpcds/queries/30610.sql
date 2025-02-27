
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender AS gender,
           COALESCE(ss.total_sales, 0) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.customer_sk
    WHERE COALESCE(ss.total_sales, 0) >= 1000
)
SELECT ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
       hvc.gender,
       hvc.total_sales,
       CASE
           WHEN hvc.total_sales > 5000 THEN 'VIP'
           WHEN hvc.total_sales BETWEEN 2000 AND 5000 THEN 'Gold'
           ELSE 'Silver'
       END AS customer_tier
FROM customer_hierarchy ch
JOIN high_value_customers hvc ON ch.c_customer_sk = hvc.c_customer_sk
ORDER BY hvc.total_sales DESC, customer_name ASC
LIMIT 50;
