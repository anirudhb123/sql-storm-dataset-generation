
WITH RECURSIVE customer_rewards AS (
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           SUM(COALESCE(ss.ss_net_profit, 0)) AS total_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(COALESCE(ss.ss_net_profit, 0)) > 0
),
ranked_rewards AS (
    SELECT c.*, 
           DENSE_RANK() OVER (ORDER BY total_profit DESC) AS reward_rank 
    FROM customer_rewards c
),
active_customers AS (
    SELECT DISTINCT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           hd.hd_income_band_sk,
           COALESCE(ib.ib_upper_bound, 0) AS upper_income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
)
SELECT r.c_first_name || ' ' || r.c_last_name AS r_customer_name, 
       r.total_profit, 
       a.cd_gender, 
       a.cd_marital_status, 
       CASE 
           WHEN a.upper_income_band > 100000 THEN 'High Income'
           WHEN a.upper_income_band BETWEEN 50000 AND 100000 THEN 'Middle Income'
           ELSE 'Low Income'
       END AS income_category,
       CASE 
           WHEN EXISTS (SELECT 1 
                        FROM store s 
                        WHERE s.s_manager IS NOT NULL
                        AND s.s_store_sk IN (SELECT ss.ss_store_sk 
                                             FROM store_sales ss 
                                             WHERE ss.ss_customer_sk = r.c_customer_sk)
                        ) THEN 'Active Store Associate'
           ELSE 'Inactive Store Associate'
       END AS store_associate_status
FROM ranked_rewards r
JOIN active_customers a ON r.c_customer_sk = a.cd_demo_sk
WHERE NOT EXISTS (
    SELECT 1 
    FROM store_returns sr 
    WHERE sr.sr_customer_sk = r.c_customer_sk 
    AND sr.sr_return_quantity > 0
)
ORDER BY total_profit DESC, a.cd_marital_status ASC
LIMIT 10;
