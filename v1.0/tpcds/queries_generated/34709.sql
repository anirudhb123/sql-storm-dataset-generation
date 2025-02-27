
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, ss_sold_date_sk, ss_quantity, ss_sales_price,
           ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - INTERVAL '30 days'
),
recent_sales AS (
    SELECT s_store_sk, SUM(ss_sales_price) AS total_sales, COUNT(*) AS sales_count
    FROM sales_hierarchy
    WHERE rn <= 10
    GROUP BY s_store_sk
),
customer_sale_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           SUM(ss.ss_sales_price) AS total_spent,
           COUNT(ss.ss_ticket_number) AS total_transactions
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_birth_year > 1980
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_summary AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           SUM(cs.cs_net_profit) AS total_profit
    FROM customer_demographics cd
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT d.cd_gender, d.cd_marital_status, d.customer_count,
       COALESCE(d.total_profit, 0) AS total_profit,
       COALESCE(r.total_sales, 0) AS recent_store_sales
FROM demographic_summary d
LEFT JOIN (
    SELECT rh.s_store_sk, rh.total_sales
    FROM recent_sales rh
    GROUP BY rh.s_store_sk
) r ON r.s_store_sk = (
    SELECT s_store_sk 
    FROM store 
    ORDER BY s_number_employees DESC 
    LIMIT 1
)
ORDER BY d.cd_gender, d.cd_marital_status;
