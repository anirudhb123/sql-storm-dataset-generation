
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_sold_date_sk) AS purchase_days
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales,
        cs.order_count,
        cs.purchase_days,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(tc.total_sales) AS avg_sales,
        AVG(tc.order_count) AS avg_orders,
        COUNT(tc.c_customer_id) AS customer_count
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    WHERE 
        tc.sales_rank <= 100
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.avg_sales,
    da.avg_orders,
    da.customer_count,
    (SELECT COUNT(*) FROM TopCustomers) AS total_top_customers
FROM 
    DemographicAnalysis da
WHERE 
    da.customer_count > 0
ORDER BY 
    da.avg_sales DESC;
