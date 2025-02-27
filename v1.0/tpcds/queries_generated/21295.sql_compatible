
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound 
    FROM income_band 
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib 
    JOIN income_brackets ibr ON ibr.ib_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound < ibr.ib_lower_bound
), 
demographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           COALESCE(ib.ib_income_band_sk, -1) AS income_band_sk,
           cd.cd_credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer_demographics cd
    LEFT JOIN income_brackets ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
), 
sales_data AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(ws.ws_order_number) AS order_count,
           MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
performance_metrics AS (
    SELECT d.cd_demo_sk,
           d.cd_gender,
           d.income_band_sk,
           s.total_net_profit,
           s.order_count,
           DENSE_RANK() OVER (PARTITION BY d.income_band_sk ORDER BY s.total_net_profit DESC) AS income_rank,
           s.last_order_date
    FROM demographics d
    JOIN sales_data s ON d.cd_demo_sk = s.ws_bill_customer_sk
)
SELECT 
    pm.cd_gender,
    COUNT(pm.cd_demo_sk) AS customer_count,
    AVG(pm.total_net_profit) AS avg_net_profit,
    SUM(pm.order_count) AS total_orders,
    MIN(pm.last_order_date) AS first_order_date,
    MAX(pm.last_order_date) AS last_order_date,
    CASE 
        WHEN AVG(pm.total_net_profit) IS NULL THEN 'No Sales'
        WHEN AVG(pm.total_net_profit) > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM performance_metrics pm
JOIN customer c ON pm.cd_demo_sk = c.c_customer_sk
LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY pm.cd_gender
HAVING COUNT(pm.cd_demo_sk) > 5
ORDER BY customer_count DESC, avg_net_profit DESC;
