
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    total_orders,
    d.d_month AS sales_month
FROM 
    TopCustomers t
JOIN 
    (SELECT 
         c.c_customer_id,
         COUNT(ws.ws_order_number) AS total_orders
     FROM 
         customer c
     JOIN 
         web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
     GROUP BY 
         c.c_customer_id) sales_count ON t.c_customer_id = sales_count.c_customer_id
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = t.c_customer_sk)
WHERE 
    t.sales_rank <= 10
ORDER BY 
    total_sales DESC;
