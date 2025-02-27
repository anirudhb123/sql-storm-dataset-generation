
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_closed_date_sk,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL
    
    UNION ALL
    
    SELECT 
        s.store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_closed_date_sk,
        sh.level + 1
    FROM 
        store s
    INNER JOIN sales_hierarchy sh ON s.s_division_id = sh.s_store_sk
    WHERE 
        sh.level < 5
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
)

SELECT 
    sh.s_store_name,
    CASE 
        WHEN sh.s_number_employees < 10 THEN 'Small'
        WHEN sh.s_number_employees BETWEEN 10 AND 50 THEN 'Medium'
        ELSE 'Large'
    END AS store_size,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    'Sales records on ' || 
        TO_CHAR(d.d_date, 'Month DD, YYYY') || 
        ' indicate a customer spending trend.' AS sales_comment
FROM 
    sales_hierarchy sh
FULL OUTER JOIN top_customers tc ON sh.s_store_sk = tc.c_customer_id
CROSS JOIN date_dim d
WHERE 
    d.d_date BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    AND (tc.total_sales IS NOT NULL OR sh.s_store_name IS NOT NULL)
ORDER BY 
    sh.s_store_name NULLS FIRST, 
    tc.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
