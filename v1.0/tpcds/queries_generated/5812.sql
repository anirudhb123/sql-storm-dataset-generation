
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
IncomeStats AS (
    SELECT 
        cd.cd_income_band_sk,
        AVG(cs.total_web_sales) AS avg_web_sales,
        AVG(cs.total_catalog_sales) AS avg_catalog_sales,
        AVG(cs.total_store_transactions) AS avg_store_transactions
    FROM 
        CustomerSales cs
    JOIN 
        household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band cd ON hd.hd_income_band_sk = cd.ib_income_band_sk
    GROUP BY 
        cd.cd_income_band_sk
),
FinalStats AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        is.avg_web_sales,
        is.avg_catalog_sales,
        is.avg_store_transactions
    FROM 
        IncomeStats is
    JOIN 
        income_band ib ON is.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    fs.ib_income_band_sk,
    fs.ib_lower_bound,
    fs.ib_upper_bound,
    COALESCE(fs.avg_web_sales, 0) AS avg_web_sales,
    COALESCE(fs.avg_catalog_sales, 0) AS avg_catalog_sales,
    COALESCE(fs.avg_store_transactions, 0) AS avg_store_transactions
FROM 
    FinalStats fs
ORDER BY 
    fs.ib_income_band_sk;
