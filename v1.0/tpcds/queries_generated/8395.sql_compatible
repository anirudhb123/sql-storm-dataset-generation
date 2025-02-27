
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_id
),
SalesRanked AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        cs.avg_transaction_value,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.sales_rank,
    sr.c_customer_id,
    sr.total_sales,
    sr.total_transactions,
    sr.avg_transaction_value,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesRanked sr
JOIN 
    customer_demographics cd ON sr.c_customer_id = cd.cd_demo_sk
WHERE 
    sr.sales_rank <= 100
ORDER BY 
    sr.total_sales DESC;
