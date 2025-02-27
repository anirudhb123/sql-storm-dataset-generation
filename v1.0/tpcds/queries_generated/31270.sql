
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bracket ib_rec ON ib.ib_lower_bound = ib_rec.ib_upper_bound + 1
),
customer_details AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           hd.hd_income_band_sk, hd.hd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk AS customer_id,
           SUM(ws_net_paid_inc_tax) AS total_spent,
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status,
       COALESCE(hb.ib_lower_bound, 'Unknown') AS income_lower_bound, 
       COALESCE(hb.ib_upper_bound, 'Unknown') AS income_upper_bound,
       ss.total_spent, ss.total_orders,
       CASE 
           WHEN ss.total_spent IS NULL THEN 'No Sales'
           WHEN ss.total_spent >= 1000 THEN 'High Value'
           WHEN ss.total_spent >= 500 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value_segment
FROM customer_details cd
LEFT JOIN income_bracket hb ON cd.hd_income_band_sk = hb.ib_income_band_sk
LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.customer_id
WHERE (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'M')
  AND (cd.cd_credit_rating IS NOT NULL OR cd.cd_credit_rating <> 'Poor')
ORDER BY cd.c_last_name, cd.c_first_name;
