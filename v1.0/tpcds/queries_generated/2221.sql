
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
SalesRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        NTILE(10) OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_tier
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales IS NOT NULL 
        OR cs.total_catalog_sales IS NOT NULL 
        OR cs.total_store_sales IS NOT NULL
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN sr.returned_date_sk IS NOT NULL THEN sr.return_net_loss ELSE 0 END) AS total_returns,
        SUM(cs.total_web_sales) AS web_sales_by_income,
        SUM(cs.total_catalog_sales) AS catalog_sales_by_income,
        SUM(cs.total_store_sales) AS store_sales_by_income
    FROM 
        household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON hd.hd_demo_sk = sr.sr_customer_sk
    LEFT JOIN CustomerSales cs ON cs.c_customer_sk = hd.hd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.total_store_sales,
    sr.sales_tier,
    ib.is_income_band_sk,
    ib.total_returns,
    ib.web_sales_by_income,
    ib.catalog_sales_by_income,
    ib.store_sales_by_income
FROM 
    SalesRanked sr
FULL OUTER JOIN IncomeBandSales ib ON sr.sales_tier = ib.ib_income_band_sk
WHERE 
    (sr.total_web_sales > 1000 OR sr.sales_tier = 1)
    AND (ib.total_returns IS NULL OR ib.total_returns < 500)
ORDER BY 
    sr.sales_tier, sr.c_last_name, sr.c_first_name;
