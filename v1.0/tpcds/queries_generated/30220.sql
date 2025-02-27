
WITH RECURSIVE sales_hierarchy (customer_sk, total_sales, level) AS (
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        s.ss_customer_sk
    
    UNION ALL
    
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_ext_sales_price) + sh.total_sales,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.customer_sk
    WHERE 
        s.ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        s.ss_customer_sk, sh.total_sales, sh.level
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        sh.total_sales
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
    WHERE 
        sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy)
    ORDER BY 
        sh.total_sales DESC
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    tc.full_name,
    tc.total_sales,
    ms.monthly_total_sales,
    CASE 
        WHEN ms.monthly_total_sales IS NULL THEN 0
        ELSE ms.monthly_total_sales - tc.total_sales
    END AS sales_difference,
    COALESCE(NULLIF(ROUND(100.0 * tc.total_sales / NULLIF(ms.monthly_total_sales, 0), 2), 0), 0) AS sales_percentage
FROM 
    top_customers tc
LEFT JOIN 
    monthly_sales ms ON ms.d_year = (SELECT MAX(d_year) FROM monthly_sales)
ORDER BY 
    tc.total_sales DESC, sales_difference ASC;
