
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesWithDemographics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        CustomerSales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
),
RankedSales AS (
    SELECT 
        sw.c_customer_id,
        sw.total_sales,
        sw.order_count,
        sw.cd_gender,
        sw.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY sw.cd_gender ORDER BY sw.total_sales DESC) AS sales_rank
    FROM 
        SalesWithDemographics sw
)
SELECT 
    rs.c_customer_id,
    rs.total_sales,
    rs.order_count,
    rs.cd_gender,
    rs.cd_marital_status
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
    AND rs.total_sales IS NOT NULL
    AND (rs.cd_gender = 'F' OR rs.cd_marital_status IS NULL)
ORDER BY 
    rs.cd_gender, rs.total_sales DESC;
