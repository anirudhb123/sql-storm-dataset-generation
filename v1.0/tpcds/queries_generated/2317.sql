
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesDemographics AS (
    SELECT 
        cs.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            WHEN cd.cd_dep_count < 2 THEN 'Single/No Dependents'
            ELSE 'Coupled/With Dependents'
        END AS customer_category
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        sd.cd_gender,
        sd.customer_category,
        COUNT(*) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        MAX(cs.total_sales) AS max_sales,
        MIN(cs.total_sales) AS min_sales
    FROM 
        SalesDemographics sd
    JOIN 
        CustomerSales cs ON sd.c_customer_id = cs.c_customer_id
    GROUP BY 
        sd.cd_gender, sd.customer_category
)
SELECT 
    s.cd_gender,
    s.customer_category,
    s.customer_count,
    s.avg_sales,
    s.max_sales,
    s.min_sales,
    RANK() OVER (PARTITION BY s.cd_gender ORDER BY s.avg_sales DESC) AS sales_rank
FROM 
    SalesSummary s
WHERE 
    s.customer_count > 1
ORDER BY 
    s.cd_gender, s.avg_sales DESC;
