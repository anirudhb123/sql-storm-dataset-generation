
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, ROW_NUMBER() OVER (ORDER BY d_date) AS rn
    FROM date_dim
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
customer_info AS (
    SELECT c.c_customer_sk,
           SUM(COALESCE(ss.ss_sales_price, 0)) AS total_spent,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
           cd_cd_gender,
           cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT c.c_customer_id,
           ci.total_spent,
           ci.total_purchases,
           ci.cd_gender,
           ci.cd_marital_status
    FROM customer_info ci
    JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
    WHERE ci.total_purchases > 5
      AND ci.gender_rank <= 10
)
SELECT t.rd_date,
       COUNT(tc.c_customer_id) AS num_customers,
       SUM(tc.total_spent) AS total_sales,
       AVG(tc.total_spent) AS avg_sales_per_customer,
       MAX(tc.total_spent) AS max_spent,
       MIN(tc.total_spent) AS min_spent,
       STRING_AGG(DISTINCT tc.cd_gender) AS gender_distribution
FROM sales_dates t
LEFT JOIN top_customers tc ON t.d_date_sk IN (SELECT ws_ship_date_sk FROM web_sales WHERE ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c))
WHERE EXISTS (SELECT 1 
              FROM customer o 
              WHERE o.c_preferred_cust_flag = 'Y' 
               AND o.c_current_cdemo_sk IS NOT NULL)
GROUP BY t.d_date
ORDER BY t.d_date DESC
LIMIT 50 OFFSET 10;
