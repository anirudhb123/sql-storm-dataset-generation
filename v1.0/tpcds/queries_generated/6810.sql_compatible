
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_sales,
        RANK() OVER (ORDER BY cp.total_sales DESC) AS sales_rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
