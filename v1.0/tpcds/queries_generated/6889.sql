
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_sales_price
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
),
SalesRanked AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesDemographics sd
)
SELECT 
    s.cd_gender,
    COUNT(*) AS customer_count,
    SUM(s.total_sales) AS total_sales,
    AVG(s.avg_sales_price) AS avg_sales_price_per_customer
FROM 
    SalesRanked s
WHERE 
    s.sales_rank <= 10
GROUP BY 
    s.cd_gender
ORDER BY 
    total_sales DESC;
