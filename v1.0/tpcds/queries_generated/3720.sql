
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_web_orders,
        cs.total_catalog_orders,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(COALESCE(cs.total_sales, 0)) AS income_band_sales
    FROM 
        SalesSummary cs
    JOIN 
        household_demographics hd ON cs.c_customer_id = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ibs.income_band_sales,
    CASE 
        WHEN ibs.income_band_sales IS NULL THEN 'No Sales'
        WHEN ibs.income_band_sales < 1000 THEN 'Low Sales'
        WHEN ibs.income_band_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    income_band ib
LEFT JOIN 
    IncomeBandSales ibs ON ib.ib_income_band_sk = ibs.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
