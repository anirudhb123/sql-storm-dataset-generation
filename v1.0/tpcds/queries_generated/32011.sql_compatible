
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales + COALESCE(SUM(rs.rs_net_profit), 0) AS total_sales,
        sh.total_orders + COUNT(rs.rs_ticket_number) AS total_orders
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        (SELECT sr.ss_net_profit, sr.ss_ticket_number, sr.ss_customer_sk 
         FROM store_returns sr
         WHERE sr.ss_returned_date_sk IS NOT NULL) rs ON sh.c_customer_sk = rs.ss_customer_sk
    GROUP BY 
        sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.total_sales, sh.total_orders
),
ranked_sales AS (
    SELECT 
        sh.c_customer_sk,
        CONCAT(sh.c_first_name, ' ', sh.c_last_name) AS full_name,
        sh.total_sales,
        sh.total_orders,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
)
SELECT 
    r.full_name,
    r.total_sales,
    r.total_orders,
    r.sales_rank,
    d.d_date AS purchase_date
FROM 
    ranked_sales r
CROSS JOIN 
    date_dim d 
WHERE 
    r.sales_rank <= 10
    AND d.d_year = 2023
    AND r.total_sales > (
        SELECT AVG(total_sales) FROM ranked_sales
    )
ORDER BY 
    r.total_sales DESC;
