
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_market_id,
        s_market_desc,
        0 AS level
    FROM 
        store
    WHERE 
        s_number_employees > 50
    
    UNION ALL
    
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_market_id,
        s_market_desc,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_market_id = sh.s_market_id
    WHERE 
        s.s_number_employees <= 50
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *
    FROM 
        customer_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    sh.s_store_name,
    sh.s_market_desc,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COUNT(wr_order_number) AS web_return_count,
    SUM(NULLIF(wr_return_amt, 0)) AS total_return_amount,
    AVG(NULLIF(wr_return_tax, 0)) AS average_return_tax
FROM 
    sales_hierarchy sh
LEFT JOIN 
    top_customers tc ON sh.s_store_sk = tc.c_customer_sk
LEFT JOIN 
    web_returns wr ON tc.c_customer_sk = wr.wr_returning_customer_sk
GROUP BY 
    sh.s_store_name, sh.s_market_desc, tc.c_first_name, tc.c_last_name
HAVING 
    SUM(COALESCE(NULLIF(tc.total_sales, 0), 0) + NULLIF(total_return_amount, 0)) > 500
ORDER BY 
    total_sales DESC, web_return_count ASC;
