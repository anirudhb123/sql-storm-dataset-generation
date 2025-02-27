
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_ranges ir ON ib.ib_lower_bound > ir.ib_upper_bound
),
customer_returns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_dep_college_count
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    d.cd_gender,
    SUM(ss.total_web_sales) AS total_web_sales,
    SUM(ss.total_catalog_sales) AS total_catalog_sales,
    SUM(ss.total_store_sales) AS total_store_sales,
    AVG(dr.total_store_returns) AS avg_store_returns,
    AVG(dr.total_web_returns) AS avg_web_returns,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    COUNT(DISTINCT ir.ib_income_band_sk) AS income_band_count
FROM demographics d
JOIN sales_summary ss ON d.cd_demo_sk = ss.c_customer_sk
JOIN customer_returns dr ON ss.c_customer_sk = dr.c_customer_sk
JOIN income_ranges ir ON d.hd_income_band_sk = ir.ib_income_band_sk
WHERE d.cd_purchase_estimate > 1000
AND d.cd_dep_count IS NOT NULL
GROUP BY d.cd_gender
ORDER BY total_web_sales DESC;
