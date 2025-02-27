
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
RecentReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns 
    FROM catalog_returns 
    GROUP BY cr_returning_customer_sk
    UNION ALL
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns 
    FROM web_returns 
    GROUP BY wr_returning_customer_sk
),
OverallMetrics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        COALESCE(rr.total_returns, 0) AS total_returns,
        CASE 
            WHEN (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) = 0 THEN NULL
            ELSE (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) - COALESCE(rr.total_returns, 0)) / 
            (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales)
        END AS net_sales_ratio
    FROM CustomerSales cs
    LEFT JOIN RecentReturns rr ON cs.c_customer_id = rr.cr_returning_customer_sk OR cs.c_customer_id = rr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    om.total_web_sales,
    om.total_catalog_sales,
    om.total_store_sales,
    om.total_returns,
    om.net_sales_ratio,
    CASE 
        WHEN om.net_sales_ratio IS NULL THEN 'No Sales'
        WHEN om.net_sales_ratio < 0 THEN 'Negative Sales'
        WHEN om.net_sales_ratio BETWEEN 0 AND 0.25 THEN 'Low Performance'
        WHEN om.net_sales_ratio BETWEEN 0.25 AND 0.5 THEN 'Moderate Performance'
        WHEN om.net_sales_ratio BETWEEN 0.5 AND 0.75 THEN 'Good Performance'
        ELSE 'Excellent Performance'
    END AS performance_category
FROM OverallMetrics om
JOIN customer c ON om.c_customer_id = c.c_customer_id
WHERE (om.total_web_sales > 1000 OR om.total_catalog_sales > 1000 OR om.total_store_sales > 1000)
AND (om.total_returns IS NULL OR om.total_returns <= 10)
ORDER BY performance_category DESC, net_sales_ratio DESC;
