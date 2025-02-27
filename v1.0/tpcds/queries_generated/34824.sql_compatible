
WITH RECURSIVE income_ranges AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        '$' || ib_lower_bound || ' - $' || ib_upper_bound AS income_band_label
    FROM income_band
    UNION ALL
    SELECT 
        ib_income_band_sk + 1,
        ib_lower_bound + 1000,
        ib_upper_bound + 1000,
        '$' || (ib_lower_bound + 1000) || ' - $' || (ib_upper_bound + 1000)
    FROM income_ranges 
    WHERE ib_income_band_sk + 1 <= 10
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT *
    FROM customer_stats
    WHERE total_spent > 1000 AND gender_rank <= 5
)
SELECT 
    ci.income_band_label,
    COUNT(tc.c_customer_id) AS customer_count,
    AVG(tc.total_spent) AS avg_spent,
    SUM(CASE WHEN tc.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN tc.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
FROM top_customers AS tc
LEFT JOIN income_ranges AS ci ON tc.total_spent BETWEEN ci.ib_lower_bound AND ci.ib_upper_bound
GROUP BY ci.income_band_label, ci.ib_income_band_sk
ORDER BY ci.ib_income_band_sk;
