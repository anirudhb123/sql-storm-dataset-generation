
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
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        csa.c_customer_id,
        csa.total_web_sales,
        csa.total_catalog_sales,
        csa.total_store_sales,
        COALESCE(csa.total_web_sales, 0) + COALESCE(csa.total_catalog_sales, 0) + COALESCE(csa.total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales csa
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(ss.total_sales) AS avg_total_sales
    FROM 
        SalesSummary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.avg_total_sales,
    RANK() OVER (ORDER BY cd.avg_total_sales DESC) AS sales_rank
FROM 
    Demographics cd
WHERE 
    cd.customer_count > 0
ORDER BY 
    sales_rank;
