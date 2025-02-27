
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000
),
SalesSummary AS (
    SELECT 
        hvc.cd_gender,
        hvc.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(hvc.total_sales) AS avg_sales,
        SUM(hvc.total_orders) AS total_orders
    FROM 
        HighValueCustomers hvc
    GROUP BY 
        hvc.cd_gender, hvc.cd_marital_status
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.customer_count,
    ss.avg_sales,
    ss.total_orders,
    ROUND((ss.avg_sales / NULLIF(ss.customer_count, 0)), 2) AS sales_per_customer
FROM 
    SalesSummary ss
ORDER BY 
    ss.customer_count DESC, ss.avg_sales DESC;
