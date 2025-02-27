
WITH RECURSIVE CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_net_paid) > 10000
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) * 1.1 AS total_sales,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        customer c
    JOIN 
        CustomerSalesCTE prev ON c.c_customer_sk = prev.c_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        prev.total_sales < 20000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CTE.total_sales,
        CTE.transaction_count,
        DENSE_RANK() OVER (ORDER BY CTE.total_sales DESC) AS sales_rank
    FROM 
        CustomerSalesCTE CTE
    JOIN 
        customer c ON c.c_customer_sk = CTE.c_customer_sk
)
SELECT 
    sr.sales_rank,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_sales,
    CASE 
        WHEN sr.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    COALESCE(cte.transaction_count, 0) AS transaction_count
FROM 
    SalesRanked sr
LEFT JOIN 
    CustomerSalesCTE cte ON sr.c_customer_sk = cte.c_customer_sk
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
