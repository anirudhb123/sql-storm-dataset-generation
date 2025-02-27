
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_ext_tax) AS total_tax
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        sales_count,
        total_discount,
        total_tax,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.sales_count,
    t.total_discount,
    t.total_tax,
    c.cd_gender,
    c.cd_marital_status
FROM 
    TopCustomers t
JOIN 
    customer_demographics c ON t.c_customer_id = c.cd_demo_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
