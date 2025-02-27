
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cd.cd_purchase_estimate) AS total_estimated_spending
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        id.ib_lower_bound,
        id.ib_upper_bound,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales
    FROM 
        CustomerSales cs
    JOIN 
        IncomeDemographics id ON cs.c_customer_id = id.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(total_sales) AS avg_sales,
    MIN(total_sales) AS min_sales,
    MAX(total_sales) AS max_sales,
    ib_lower_bound,
    ib_upper_bound
FROM 
    SalesSummary
WHERE 
    total_sales > 0
GROUP BY 
    ib_lower_bound, ib_upper_bound
ORDER BY 
    ib_lower_bound;
