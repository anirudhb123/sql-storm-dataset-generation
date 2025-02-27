
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
DemographicInfo AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT 
        c.customer_id,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        di.customer_count,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status
    FROM 
        CustomerSales cs
    JOIN Customer c ON cs.c_customer_id = c.c_customer_id
    LEFT JOIN DemographicInfo di ON di.customer_count = (
        SELECT COUNT(*)
        FROM customer 
        WHERE c.c_current_cdemo_sk = customer.c_current_cdemo_sk
    )
),
FinalSalesData AS (
    SELECT 
        total_sales,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        NTILE(4) OVER (ORDER BY total_sales) AS sales_quartile
    FROM 
        SalesSummary
)
SELECT 
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status,
    AVG(fs.total_sales) AS avg_total_sales,
    COUNT(*) AS demographic_count,
    SUM(CASE WHEN fs.sales_quartile = 1 THEN 1 ELSE 0 END) AS quartile_1_count,
    SUM(CASE WHEN fs.sales_quartile = 2 THEN 1 ELSE 0 END) AS quartile_2_count,
    SUM(CASE WHEN fs.sales_quartile = 3 THEN 1 ELSE 0 END) AS quartile_3_count,
    SUM(CASE WHEN fs.sales_quartile = 4 THEN 1 ELSE 0 END) AS quartile_4_count
FROM 
    FinalSalesData fs
GROUP BY 
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status
HAVING 
    COUNT(*) > 1
ORDER BY 
    avg_total_sales DESC;
