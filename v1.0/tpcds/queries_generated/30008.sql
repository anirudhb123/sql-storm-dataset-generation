
WITH RECURSIVE sale_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT ddd.d_date_sk, ddd.d_date, ddd.d_year
    FROM date_dim ddd
    JOIN sale_dates sd ON ddd.d_date_sk = sd.d_date_sk + 1
),
customer_stats AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(CASE WHEN cd.cd_credit_rating IS NULL THEN 1 ELSE 0 END) AS null_credit_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
store_performance AS (
    SELECT s.s_store_id,
           SUM(ss.ss_quantity) AS total_sales_quantity,
           SUM(ss.ss_net_paid) AS total_net_paid,
           AVG(ss.ss_net_profit / NULLIF(ss.ss_net_paid, 0)) AS avg_profit_margin
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
)
SELECT cs.cd_gender,
       cs.cd_marital_status,
       COALESCE(sp.total_sales_quantity, 0) AS store_total_sales_quantity,
       COALESCE(sp.total_net_paid, 0) AS store_total_net_paid,
       COALESCE(sp.avg_profit_margin, 0) AS store_avg_profit_margin,
       COUNT(sd.d_date) AS active_sale_days
FROM customer_stats cs
LEFT JOIN store_performance sp ON cs.customer_count > 100
JOIN sale_dates sd ON sd.d_year = 2023
GROUP BY cs.cd_gender, cs.cd_marital_status, sp.total_sales_quantity, sp.total_net_paid, sp.avg_profit_margin
ORDER BY cs.cd_gender, cs.cd_marital_status;
