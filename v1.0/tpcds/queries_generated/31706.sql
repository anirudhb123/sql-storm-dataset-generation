
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.c_customer_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sales_price,
        1 AS sales_level
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price > 100

    UNION ALL

    SELECT 
        cs.c_customer_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sales_price * 1.1 AS cs_sales_price,
        sales_level + 1
    FROM 
        catalog_sales cs
        JOIN sales_hierarchy sh ON cs.c_customer_sk = sh.c_customer_sk
    WHERE 
        sh.sales_level < 3
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(sh.cs_sales_price), 0) AS total_sales,
    COUNT(DISTINCT sh.cs_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_country ORDER BY COALESCE(SUM(sh.cs_sales_price), 0) DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    COALESCE(SUM(sh.cs_sales_price), 0) > 500
ORDER BY 
    total_sales DESC, c.c_last_name ASC

FETCH FIRST 10 ROWS ONLY;
