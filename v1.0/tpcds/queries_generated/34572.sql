
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_sales_price,
        s.ss_quantity,
        s.ss_sold_date_sk,
        DATE(d.d_date) AS sold_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    UNION ALL
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        s.ss_sales_price,
        s.ss_quantity,
        s.ss_sold_date_sk,
        DATE(d.d_date) AS sold_date,
        ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS rank
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales s ON sh.c_customer_sk = s.ss_customer_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        sh.rank < 5 AND
        d.d_year = 2023
),
total_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(sh.ss_sales_price * sh.ss_quantity) AS total_spent,
        COUNT(*) AS total_transactions
    FROM 
        sales_hierarchy sh
    INNER JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT 
    th.c_customer_sk,
    th.c_first_name,
    th.c_last_name,
    COALESCE(ts.total_spent, 0) AS total_spent,
    COALESCE(ts.total_transactions, 0) AS total_transactions,
    CASE 
        WHEN COALESCE(ts.total_spent, 0) > 1000 THEN 'High Roller'
        WHEN COALESCE(ts.total_spent, 0) > 500 THEN 'Moderate Spender'
        ELSE 'Casual Shopper'
    END AS customer_segment
FROM 
    customer th
LEFT JOIN 
    total_sales ts ON th.c_customer_sk = ts.c_customer_sk
ORDER BY 
    total_spent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
