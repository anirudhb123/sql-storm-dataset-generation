
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        0 AS level,
        CAST(c.c_customer_id AS CHAR(100)) AS path
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        
    UNION ALL
    
    SELECT 
        sr.sr_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        CONCAT(sh.path, ' -> ', c.c_customer_id)
    FROM 
        sales_hierarchy sh
    JOIN 
        store_returns sr ON sh.c_customer_sk = sr.sr_customer_sk
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
), sales_summary AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY dd.d_year ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
    HAVING 
        SUM(ws.ws_sales_price) > 10000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    sh.level,
    sales_summary.total_sales,
    sales_summary.order_count,
    CASE WHEN sh.level > 0 THEN 'Not First-Time' ELSE 'First-Time' END AS customer_type,
    NULLIF(sh.path, '') AS customer_path
FROM 
    sales_hierarchy sh
LEFT JOIN 
    sales_summary ON sales_summary.sales_rank <= 5
JOIN 
    customer c ON c.c_customer_sk = sh.c_customer_sk
WHERE 
    sh.level < 3
ORDER BY 
    sales_summary.total_sales DESC, sh.level;
