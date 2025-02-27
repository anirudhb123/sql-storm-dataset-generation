
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE 
        cs.sales_rank <= 10
),
DailySales AS (
    SELECT 
        dd.d_date AS sale_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
    ORDER BY 
        dd.d_date
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.avg_sales_price,
    ds.sale_date,
    ds.daily_sales
FROM 
    TopCustomers tc
JOIN 
    DailySales ds ON tc.total_sales > ds.daily_sales
ORDER BY 
    tc.total_sales DESC, ds.sale_date ASC;
