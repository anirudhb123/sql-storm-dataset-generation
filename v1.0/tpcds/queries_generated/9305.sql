
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(bs.ss_net_paid) AS total_sales,
        COUNT(bs.ss_ticket_number) AS total_transactions,
        AVG(bs.ss_net_paid) AS average_transaction_value
    FROM 
        customer c
    JOIN 
        store_sales bs ON c.c_customer_sk = bs.ss_customer_sk
    JOIN 
        date_dim d ON bs.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
), TopCustomers AS (
    SELECT 
        c.customer_id, 
        cs.total_sales, 
        cs.total_transactions, 
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_transactions > 10
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.sales_rank,
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
