
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS customer_name,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.customer_name,
        sh.total_sales * 1.1 AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
sales_summary AS (
    SELECT
        sh.customer_name,
        sh.total_sales,
        COALESCE(NULLIF(c.c_birth_month, 0), 1) AS birth_month,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
),
top_customers AS (
    SELECT 
        customer_name,
        total_sales,
        birth_month
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.customer_name,
    t.total_sales,
    a.ca_city,
    a.ca_state,
    CASE 
        WHEN t.birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN t.birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN t.birth_month BETWEEN 7 AND 9 THEN 'Q3'
        WHEN t.birth_month BETWEEN 10 AND 12 THEN 'Q4'
        ELSE 'Unknown'
    END AS birth_quarter
FROM 
    top_customers t
LEFT JOIN 
    customer_address a ON t.customer_name LIKE '%' || a.ca_street_name || '%'
ORDER BY 
    t.total_sales DESC;
