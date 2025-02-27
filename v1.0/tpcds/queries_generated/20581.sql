
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound 
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
), customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           d.d_date,
           cd.cd_gender,
           h.hd_income_band_sk,
           h.hd_buy_potential,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM customer c
    JOIN household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
), sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_spent,
           COUNT(*) AS purchase_count,
           AVG(ws_net_paid) AS avg_spent,
           MAX(ws_net_paid) AS max_spent,
           MIN(ws_net_paid) AS min_spent
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), condition_checks AS (
    SELECT ci.c_first_name,
           ci.c_last_name,
           ci.cd_gender,
           ci.hd_income_band_sk,
           ss.total_spent,
           ss.purchase_count,
           ss.avg_spent,
           CASE 
               WHEN ss.total_spent IS NULL THEN 'No Purchases'
               WHEN ss.avg_spent > 100 THEN 'High Value'
               ELSE 'Low Value'
           END AS customer_value_category
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ci.rn = 1
)
SELECT ic.ib_income_band_sk,
       ic.ib_lower_bound,
       ic.ib_upper_bound,
       COUNT(DISTINCT cc.c_first_name || ' ' || cc.c_last_name) AS customer_count,
       SUM(CASE WHEN cc.customer_value_category = 'High Value' THEN 1 ELSE 0 END) AS high_value_count,
       SUM(CASE WHEN cc.customer_value_category = 'Low Value' THEN 1 ELSE 0 END) AS low_value_count,
       AVG(cc.total_spent) AS avg_spent_per_income_bracket
FROM income_bracket ic
LEFT JOIN condition_checks cc ON ic.ib_income_band_sk = cc.hd_income_band_sk
GROUP BY ic.ib_income_band_sk, ic.ib_lower_bound, ic.ib_upper_bound
ORDER BY ic.ib_income_band_sk
WITH ROLLUP;
