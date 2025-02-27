
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.total_orders,
    d.d_year,
    SUM(DISTINCT CASE WHEN EXTRACT(MONTH FROM d.d_date) = 12 THEN ws.ws_ext_sales_price ELSE 0 END) AS december_sales,
    COUNT(DISTINCT CASE WHEN d.d_holiday = 'Y' THEN ws.ws_order_number END) AS holiday_orders
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON d.d_date_sk IN (SELECT ws.ws_sold_date_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.customer_sk)
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.first_name, tc.last_name, tc.total_sales, tc.total_orders, d.d_year
ORDER BY 
    tc.total_sales DESC;
