
WITH RECURSIVE income_groups AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_groups ig ON ib.ib_lower_bound <= ig.ib_upper_bound
    WHERE ib.ib_income_band_sk < ig.ib_income_band_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status IS NULL THEN 'N/A'
            ELSE 'Single'
        END AS marital_status,
        COUNT(DISTINCT cd.cd_demo_sk) OVER(PARTITION BY cd.cd_gender) AS gender_count,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        ws.ws_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_status,
    ci.gender_count,
    CASE 
        WHEN ss.order_count > 5 THEN 'High Spender'
        WHEN ss.order_count BETWEEN 3 AND 5 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spender_category,
    ig.ib_lower_bound AS income_lower_bound,
    ig.ib_upper_bound AS income_upper_bound
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_customer_sk
JOIN income_groups ig ON ci.hd_income_band_sk = ig.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store s
    WHERE s.s_store_sk = (
        SELECT MAX(s2.s_store_sk)
        FROM store s2
        INNER JOIN store_sales ss2 ON s2.s_store_sk = ss2.ss_store_sk
        WHERE ss2.ss_customer_sk = ci.c_customer_sk
    )
)
AND ci.marital_status IS NOT NULL
ORDER BY ci.c_last_name, ci.c_first_name;
