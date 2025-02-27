
WITH RankedSales AS (
    SELECT 
        s.s_store_sk,
        s.ss_quantity,
        s.ss_sales_price,
        s.ss_net_paid,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY s.ss_net_paid DESC) AS sales_rank
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        s.ss_sold_date_sk BETWEEN 20230101 AND 20231231
),
TopCustomers AS (
    SELECT 
        r.c_first_name,
        r.c_last_name,
        r.ss_net_paid,
        r.s_store_sk,
        r.d_date
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    t.s_store_sk,
    COUNT(t.c_first_name) AS top_customers_count,
    SUM(t.ss_net_paid) AS total_net_paid,
    AVG(t.ss_net_paid) AS avg_net_paid
FROM 
    TopCustomers t
JOIN 
    store st ON t.s_store_sk = st.s_store_sk
GROUP BY 
    t.s_store_sk
ORDER BY 
    total_net_paid DESC;
