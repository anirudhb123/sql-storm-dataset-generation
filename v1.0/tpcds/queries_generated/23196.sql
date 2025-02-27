
WITH TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           COALESCE(cd.cd_gender, 'Unknown') AS gender,
           COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
           SUM(ss.ss_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY COALESCE(cd.cd_marital_status, 'Unknown') ORDER BY SUM(ss.ss_net_profit) DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_first_name IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT d.d_year,
           SUM(ss.ss_net_sales) AS total_sales,
           COUNT(DISTINCT ss.ss_customer_sk) AS customer_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
AnnualPerformance AS (
    SELECT s.d_year,
           SUM(s.total_sales) OVER (ORDER BY s.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
           AVG(s.customer_count) OVER (ORDER BY s.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS average_customers
    FROM SalesSummary s
)
SELECT tc.c_customer_id, 
       tc.gender, 
       tc.marital_status, 
       ap.cumulative_sales,
       ap.average_customers
FROM TopCustomers tc
JOIN AnnualPerformance ap ON ap.d_year = (SELECT MAX(d_year) FROM AnnualPerformance) 
WHERE tc.rn <= 10 
AND ap.cumulative_sales IS NOT NULL
ORDER BY tc.total_profit DESC, ap.average_customers DESC;
