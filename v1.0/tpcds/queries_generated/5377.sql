
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.sales_count,
        cs.avg_sales_price,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id, 
    tc.total_sales, 
    tc.sales_count, 
    tc.avg_sales_price, 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
