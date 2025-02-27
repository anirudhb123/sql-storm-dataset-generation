
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
),
total_sales AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_ship) AS total_net_sales,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
customer_demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT ch.c_first_name,
       ch.c_last_name,
       COALESCE(td.total_net_sales, 0) AS total_sales,
       COALESCE(td.total_orders, 0) AS total_orders,
       cd.customer_count,
       (ROW_NUMBER() OVER (PARTITION BY cd.cd_demo_sk ORDER BY total_sales DESC)) AS sales_rank,
       CASE
           WHEN cd.cd_gender = 'M' THEN 'Male'
           WHEN cd.cd_gender = 'F' THEN 'Female'
           ELSE 'Other'
       END AS gender_description
FROM customer_hierarchy ch
LEFT JOIN total_sales td ON ch.c_customer_sk = td.ws_bill_customer_sk
JOIN customer_demographics cd ON ch.c_customer_sk = cd.cd_demo_sk
WHERE td.total_net_sales > 1000
ORDER BY total_sales DESC, ch.c_last_name ASC
LIMIT 100;
