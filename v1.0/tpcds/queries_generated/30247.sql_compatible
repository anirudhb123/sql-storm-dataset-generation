
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    INNER JOIN income_bracket ib_prev ON ib.ib_lower_bound = ib_prev.ib_upper_bound + 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_net_paid) AS total_spent,
        MAX(s.ss_sold_date_sk) AS last_purchase_date,
        AVG(COALESCE(s.ss_net_paid, 0)) AS avg_purchase
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.total_purchases) AS total_purchases,
    SUM(cs.total_spent) AS total_spent,
    AVG(cs.avg_purchase) AS avg_spent_per_customer,
    CASE 
        WHEN SUM(cs.total_spent) IS NULL THEN 'No Spending'
        WHEN SUM(cs.total_spent) < 1000 THEN 'Low Spender'
        WHEN SUM(cs.total_spent) BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_profile,
    CONCAT('Gender: ', cd.cd_gender, ', Marital Status: ', cd.cd_marital_status) AS demographics_info
FROM customer_stats cs
INNER JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN income_bracket ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE cs.total_purchases > 5
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY total_spent DESC, demographics_info ASC
FETCH FIRST 10 ROWS ONLY;
