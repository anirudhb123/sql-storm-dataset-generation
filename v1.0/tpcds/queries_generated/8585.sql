
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
)
SELECT 
    t.c_first_name, 
    t.c_last_name, 
    t.total_sales,
    d.d_month,
    d.d_year,
    SUM(ss.ss_quantity) AS total_quantity_sold
FROM TopCustomers t
JOIN store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
WHERE t.sales_rank <= 10
GROUP BY t.c_first_name, t.c_last_name, t.total_sales, d.d_month, d.d_year
ORDER BY total_quantity_sold DESC;
