
WITH RECURSIVE income_groups AS (
    SELECT b.ib_income_band_sk, 
           b.ib_lower_bound, 
           b.ib_upper_bound,
           ROW_NUMBER() OVER (ORDER BY b.ib_income_band_sk) AS income_rank
    FROM income_band b
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           d.cd_marital_status,
           CASE 
               WHEN d.cd_gender = 'M' THEN 'Male'
               WHEN d.cd_gender = 'F' THEN 'Female'
               ELSE 'Other' 
           END AS gender_identity,
           COALESCE(cd.cd_dep_count, 0) AS dependent_count,
           COALESCE(cd.cd_dep_employed_count, 0) AS dependents_employed,
           COALESCE(cd.cd_dep_college_count, 0) AS dependents_in_college,
           ci.ib_income_band_sk,
           ci.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = d.cd_demo_sk
    LEFT JOIN income_groups ci ON ci.ib_income_band_sk = hd.hd_income_band_sk
),
sales_details AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
final_analysis AS (
    SELECT ci.c_first_name, 
           ci.c_last_name, 
           ci.gender_identity, 
           s.total_net_profit,
           s.order_count,
           s.avg_sales_price,
           ci.ib_upper_bound,
           RANK() OVER (PARTITION BY ci.gender_identity ORDER BY s.total_net_profit DESC) AS profit_rank
    FROM customer_info ci
    LEFT JOIN sales_details s ON ci.c_customer_sk = s.ws_bill_customer_sk
    WHERE s.total_net_profit IS NOT NULL AND ci.ib_upper_bound IS NOT NULL
)
SELECT gender_identity,
       COUNT(*) AS customer_count,
       AVG(avg_sales_price) AS avg_sales_price,
       COUNT(CASE WHEN profit_rank <= 3 THEN 1 END) AS top_profit_customers
FROM final_analysis
GROUP BY gender_identity
ORDER BY gender_identity ASC;
