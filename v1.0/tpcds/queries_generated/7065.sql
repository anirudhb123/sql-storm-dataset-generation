
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_transaction_value
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
        c.total_sales,
        c.total_transactions,
        c.average_transaction_value,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.average_transaction_value
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
