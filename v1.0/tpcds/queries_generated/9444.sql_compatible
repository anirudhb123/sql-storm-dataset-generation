
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
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
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_web_sales) AS total_web_sales_by_demo,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_demo,
        SUM(cs.total_store_sales) AS total_store_sales_by_demo
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        total_web_sales_by_demo,
        total_catalog_sales_by_demo,
        total_store_sales_by_demo,
        (total_web_sales_by_demo + total_catalog_sales_by_demo + total_store_sales_by_demo) AS total_sales
    FROM 
        DemographicSales
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_web_sales_by_demo,
    total_catalog_sales_by_demo,
    total_store_sales_by_demo,
    total_sales
FROM 
    SalesSummary
ORDER BY 
    total_sales DESC
LIMIT 10;
