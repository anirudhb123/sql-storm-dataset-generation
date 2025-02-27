
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    t.customer_id,
    t.total_sales,
    t.total_orders,
    d.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS monthly_sales
FROM 
    TopCustomers t
JOIN 
    web_sales ws ON t.customer_id = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    t.customer_id, t.total_sales, t.total_orders, d.d_month_seq
ORDER BY 
    t.total_sales DESC, d.d_month_seq ASC;
