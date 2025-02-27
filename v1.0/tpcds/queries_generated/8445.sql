
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    (SELECT COUNT(DISTINCT ws.web_site_sk)
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS total_websites_purchased_from,
    (SELECT AVG(ws.ws_sales_price) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS avg_order_value
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
