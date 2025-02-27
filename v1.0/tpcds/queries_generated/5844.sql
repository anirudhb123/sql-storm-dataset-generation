
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        total_web_sales, 
        total_catalog_sales, 
        total_store_sales,
        (CASE 
            WHEN total_web_sales IS NULL THEN 0 
            ELSE total_web_sales 
        END) +
        (CASE 
            WHEN total_catalog_sales IS NULL THEN 0 
            ELSE total_catalog_sales 
        END) +
        (CASE 
            WHEN total_store_sales IS NULL THEN 0 
            ELSE total_store_sales 
        END) AS total_sales
    FROM 
        CustomerSales
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(CASE WHEN total_sales >= ib.ib_lower_bound AND total_sales < ib.ib_upper_bound THEN 1 ELSE 0 END) AS customer_count
    FROM 
        SalesSummary ss
    JOIN 
        household_demographics hd ON ss.total_web_sales > 0 -- Assume web sales link to customer demographics
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound, 
    ib.customer_count
FROM 
    IncomeBandSales ib
ORDER BY 
    ib.ib_income_band_sk;
