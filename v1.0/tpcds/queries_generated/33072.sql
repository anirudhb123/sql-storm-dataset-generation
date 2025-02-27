
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_current_cdemo_sk
    WHERE sh.level < 5
),
aggregated_sales AS (
    SELECT
        s.ss_store_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        AVG(s.ss_net_paid) AS avg_net_paid
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    GROUP BY s.ss_store_sk
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sh.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN sales_hierarchy sh ON cd.cd_demo_sk = sh.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)

SELECT 
    a.ss_store_sk,
    COALESCE(a.total_sales, 0) AS total_sales,
    COALESCE(a.total_transactions, 0) AS total_transactions,
    COALESCE(a.avg_net_paid, 0.00) AS avg_net_paid,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM aggregated_sales a
FULL OUTER JOIN customer_demographics cd ON a.ss_store_sk = cd.cd_demo_sk
WHERE (cd.cd_purchase_estimate BETWEEN 1000 AND 10000 OR cd.cd_gender IS NULL)
  AND (cd.customer_count IS NOT NULL OR cd.cd_gender = 'F')
ORDER BY 
    total_sales DESC,
    customer_count DESC
LIMIT 100
OFFSET 10;
