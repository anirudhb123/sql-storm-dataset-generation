
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_spent,
        (SELECT COUNT(*) 
         FROM store s 
         WHERE s.s_store_sk = ss.ss_store_sk) AS store_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Sales'
            WHEN cs.total_spent < 1000 THEN 'Low Spender'
            WHEN cs.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.total_spent,
        s.spending_category,
        RANK() OVER (ORDER BY s.total_spent DESC) AS rank
    FROM 
        SalesSummary s
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.total_spent,
    t.spending_category
FROM 
    TopCustomers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_spent DESC;
