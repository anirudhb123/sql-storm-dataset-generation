
WITH CustomerReturnSummary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(sr_return_quantity), 0) DESC) AS return_rank
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_web_sales,
        SUM(cs_sales_price) AS total_catalog_sales,
        SUM(ss_sales_price) AS total_store_sales
    FROM 
        web_sales
    FULL OUTER JOIN 
        catalog_sales ON web_sales.ws_item_sk = catalog_sales.cs_item_sk
    FULL OUTER JOIN 
        store_sales ON web_sales.ws_item_sk = store_sales.ss_item_sk
    GROUP BY 
        ws_item_sk
),
IncomeDemographic AS (
    SELECT 
        cd_demo_sk,
        MIN(hd_income_band_sk) AS min_income_band,
        MAX(hd_income_band_sk) AS max_income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd_demo_sk
)
SELECT 
    cus_return.c_customer_id,
    cus_return.total_store_returns,
    cus_return.total_web_returns,
    i.total_web_sales,
    i.total_catalog_sales,
    i.total_store_sales,
    CASE 
        WHEN cus_return.return_rank IS NULL THEN 'NO RETURNS'
        ELSE 'RETURNS MADE'
    END AS return_status,
    NULLIF(income.min_income_band, income.max_income_band) AS income_band_difference,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promotions
FROM 
    CustomerReturnSummary cus_return
JOIN 
    ItemSales i ON cus_return.c_customer_id = i.ws_item_sk
LEFT JOIN 
    IncomeDemographic income ON cus_return.c_customer_id = income.cd_demo_sk
WHERE 
    (i.total_web_sales > (SELECT AVG(total_web_sales) FROM ItemSales) OR 
    i.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM ItemSales))
    AND cus_return.total_store_returns > 5
ORDER BY 
    cus_return.total_web_returns DESC
FETCH FIRST 10 ROWS ONLY;
