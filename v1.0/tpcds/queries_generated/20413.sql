
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        COUNT(DISTINCT CASE WHEN w.web_site_id IS NOT NULL THEN w.web_site_sk END) AS total_web_visits,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(ss.ss_net_profit, 0)) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_page w ON w.wp_customer_sk = c.c_customer_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_dep_count
),
IncomeBreakdown AS (
    SELECT
        h.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL THEN 
                CONCAT('$', ib.ib_lower_bound, ' to $', ib.ib_upper_bound)
            ELSE
                'Unknown Income'
        END AS income_range
    FROM household_demographics h
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
FinalStats AS (
    SELECT
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_web_visits,
        cs.total_store_profit,
        cs.total_web_profit,
        ib.income_range,
        (RANK() OVER (ORDER BY cs.total_store_profit DESC)) AS profit_rank
    FROM CustomerStats cs
    LEFT JOIN IncomeBreakdown ib ON cs.c_customer_sk = ib.hd_demo_sk
)
SELECT
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    f.total_web_visits,
    f.total_store_profit,
    f.total_web_profit,
    f.income_range,
    CASE 
        WHEN f.total_store_profit > f.total_web_profit THEN 'More profit from Store'
        WHEN f.total_web_profit > f.total_store_profit THEN 'More profit from Web'
        ELSE 'Equal profit'
    END AS profit_comparison,
    ROW_NUMBER() OVER (PARTITION BY f.cd_gender ORDER BY f.total_store_profit DESC) AS gender_based_rank
FROM FinalStats f
WHERE f.total_web_profit IS NOT NULL AND f.total_store_profit IS NOT NULL
ORDER BY f.total_store_profit DESC, f.total_web_profit ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
