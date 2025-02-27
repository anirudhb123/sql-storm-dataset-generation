
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bracket ibr ON ib.ib_income_band_sk = ibr.ib_income_band_sk + 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
store_performance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
),
sales_summary AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cs.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.total_profit,
        sp.store_profit,
        sp.total_sales,
        sp.unique_customers
    FROM customer_stats cs
    JOIN income_bracket ib ON cs.income_band = ib.ib_income_band_sk
    LEFT JOIN store_performance sp ON cs.c_customer_sk = sp.s_store_id
)
SELECT 
    full_name,
    cd_gender,
    ib_lower_bound,
    ib_upper_bound,
    COALESCE(total_profit, 0) AS total_profit,
    COALESCE(store_profit, 0) AS store_profit,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(unique_customers, 0) AS unique_customers
FROM sales_summary
WHERE 
    (COALESCE(total_profit, 0) > 1000 OR COALESCE(store_profit, 0) > 500)
    AND (cd_gender IS NOT NULL)
ORDER BY total_profit DESC, full_name;
