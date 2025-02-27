
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_id
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
ranked_demographics AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk,
        d.customer_count,
        RANK() OVER (PARTITION BY d.cd_income_band_sk ORDER BY d.customer_count DESC) AS income_rank
    FROM demographics d
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    ib.ib_lower_bound AS income_lower_bound,
    ib.ib_upper_bound AS income_upper_bound,
    r.customer_count,
    COALESCE(r.income_rank, 'N/A') AS rank_within_income_band
FROM ranked_demographics r
JOIN income_band ib ON r.cd_income_band_sk = ib.ib_income_band_sk
WHERE r.customer_count > (
    SELECT AVG(customer_count) 
    FROM ranked_demographics 
    WHERE cd_income_band_sk = r.cd_income_band_sk
) OR r.customer_count IS NULL
ORDER BY r.cd_gender, r.cd_marital_status;
