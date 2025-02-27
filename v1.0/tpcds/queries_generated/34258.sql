
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_sales AS store_sales,
        1 AS level
    FROM (
        SELECT 
            ss_store_sk,
            SUM(ss_net_paid) AS s_sales,
            s_store_name
        FROM store
        JOIN store_sales ON store.s_store_sk = store_sales.ss_store_sk
        GROUP BY ss_store_sk, s_store_name
    ) AS sales_data
    WHERE s_sales > 10000
    
    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        (sh.store_sales + COALESCE(t.total_sales, 0)) AS store_sales,
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON sh.s_store_sk = s.s_store_sk
    LEFT JOIN (
        SELECT 
            ss_store_sk,
            SUM(ss_net_paid) AS total_sales
        FROM store_sales
        GROUP BY ss_store_sk
    ) t ON t.ss_store_sk = s.s_store_sk
    WHERE sh.level < 5
)

SELECT 
    sh.s_store_name,
    sh.level,
    sh.store_sales,
    ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.store_sales DESC) AS rank,
    CASE 
        WHEN sh.store_sales IS NULL THEN 'No sales'
        ELSE CONCAT('Sales: $', CAST(sh.store_sales AS VARCHAR))
    END AS sales_info
FROM sales_hierarchy sh
ORDER BY sh.level, sh.store_sales DESC;

-- Aggregating the customer demographics
SELECT 
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    AVG(CASE WHEN c.c_birth_year IS NOT NULL THEN 2023 - c.c_birth_year ELSE NULL END) AS avg_age
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
GROUP BY cd.cd_gender
HAVING COUNT(DISTINCT c.c_customer_sk) > 20
ORDER BY avg_purchase_estimate DESC;

-- Analyzing returns combining web and store
SELECT 
    COALESCE(s.s_store_name, 'Web Sales') AS source,
    SUM(COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_return,
    SUM(COALESCE(sr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_return_quantity
FROM store_returns sr
FULL OUTER JOIN web_returns wr ON sr.sr_item_sk = wr.wr_item_sk
FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
GROUP BY ROLLUP (s.s_store_name)
ORDER BY total_return DESC;

-- Percentage calculation of sales per income band
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ws.ws_net_paid) AS total_sales,
    ROUND(SUM(ws.ws_net_paid) * 100.0 / NULLIF(SUM(SUM(ws.ws_net_paid)) OVER (), 0), 2) AS sales_percentage
FROM web_sales ws
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY ib.ib_lower_bound;

