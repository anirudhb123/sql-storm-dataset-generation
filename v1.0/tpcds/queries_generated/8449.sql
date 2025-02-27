
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
        ws.ws_sold_date_sk BETWEEN 1000000 AND 1000050
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    t_c.c_first_name,
    t_c.c_last_name,
    t_c.total_sales,
    t_c.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    dd.d_year
FROM 
    TopCustomers t_c
JOIN 
    customer_demographics cd ON t_c.c_customer_sk = cd.cd_demo_sk
JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = t_c.c_customer_sk)
WHERE 
    t_c.rank <= 10
ORDER BY 
    t_c.total_sales DESC;
