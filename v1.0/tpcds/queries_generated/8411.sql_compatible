
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
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
            c_customer_sk AS customer_sk,
            c_first_name AS first_name,
            c_last_name AS last_name
         FROM 
            customer) c
    JOIN 
        CustomerSales cs ON c.customer_sk = cs.c_customer_sk
)
SELECT 
    t.first_name,
    t.last_name,
    t.total_sales,
    t.order_count,
    d.d_month AS sales_month,
    d.d_year AS sales_year
FROM 
    TopCustomers t
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = t.customer_sk)
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
