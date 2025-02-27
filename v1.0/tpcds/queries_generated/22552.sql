
WITH RECURSIVE income_distribution AS (
    SELECT ic.ib_income_band_sk, 
           ic.ib_lower_bound, 
           ic.ib_upper_bound, 
           COUNT(DISTINCT cd.cd_demo_sk) AS num_customers,
           SUM(CASE 
                   WHEN cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate BETWEEN ic.ib_lower_bound AND ic.ib_upper_bound 
                   THEN 1 ELSE 0 END) AS customers_with_purchases
    FROM income_band ic
    LEFT JOIN customer_demographics cd ON TRUE
    GROUP BY ic.ib_income_band_sk, ic.ib_lower_bound, ic.ib_upper_bound
),
high_spenders AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_purchase_estimate, 
           RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
motivated_customers AS (
    SELECT c.c_customer_sk, 
           COALESCE(CAST(SUM(ws.ws_quantity) AS DECIMAL(10, 2)), 0) AS total_spent,
           MAX(ws.ws_sales_price) AS max_spent 
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk AND ws.ws_sales_price > 0
    WHERE c.c_current_hdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
final_summary AS (
    SELECT id.ib_income_band_sk,
           id.num_customers, 
           id.customers_with_purchases, 
           COUNT(mc.c_customer_sk) AS motivated_count,
           SUM(mc.total_spent) AS total_motivated_spent
    FROM income_distribution id
    LEFT JOIN motivated_customers mc ON id.ib_income_band_sk = 
        (SELECT hd.hd_income_band_sk 
         FROM household_demographics hd 
         WHERE hd.hd_demo_sk = mc.c_customer_sk 
         LIMIT 1) 
    GROUP BY id.ib_income_band_sk, id.num_customers, id.customers_with_purchases
)
SELECT fs.ib_income_band_sk,
       fs.num_customers,
       fs.customers_with_purchases,
       fs.motivated_count,
       fs.total_motivated_spent,
       (fs.total_motivated_spent / NULLIF(fs.motivated_count, 0)) AS avg_spent_per_motivated, 
       CASE 
           WHEN fs.total_motivated_spent > 10000 THEN 'High Roller'
           WHEN fs.total_motivated_spent BETWEEN 5000 AND 10000 THEN 'Mid Roller'
           ELSE 'Low Roller' 
       END AS spending_category
FROM final_summary fs
JOIN customer c ON fs.motivated_count = (SELECT COUNT(*) FROM motivated_customers WHERE c.c_customer_sk = c.c_customer_sk)
ORDER BY 1;
