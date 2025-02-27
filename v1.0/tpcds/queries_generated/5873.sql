
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459485 AND 2459520  -- Date range for analysis
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000  -- Filter for customers with significant sales
),

TopCustomers AS (
    SELECT 
        c.*, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM 
        CustomerSales c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    ORDER BY 
        c.total_sales DESC
    LIMIT 10  -- Top 10 customers
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ROUND(tc.total_sales::numeric, 2) AS total_sales
FROM 
    TopCustomers tc
ORDER BY 
    total_sales DESC;

-- Performance benchmarking: total sales of top customers by gender and education status.
