
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_name, 
        ws.web_manager, 
        ws.web_sales_price, 
        ws.ws_order_number,
        1 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459439 AND 2459445 -- A specific date range

    UNION ALL

    SELECT 
        ws.web_site_sk, 
        ws.web_name, 
        ws.web_manager, 
        ws.web_sales_price + sh.web_sales_price AS web_sales_price,
        ws.ws_order_number,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_hierarchy sh ON ws.ws_order_number = sh.ws_order_number
    WHERE 
        sh.level < 5 -- Limit recursion for depth
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.c_birth_year,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales,
    MAX(ws.ws_sales_price) AS max_sales,
    MIN(ws.ws_sales_price) AS min_sales,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    sales_hierarchy sh
LEFT JOIN 
    customer c ON c.c_customer_sk = sh.web_site_sk -- Customer information
LEFT JOIN 
    web_sales ws ON ws.ws_order_number = sh.ws_order_number -- Join to bring in sales data
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    c.c_birth_year
HAVING 
    SUM(ws.ws_sales_price) > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2) -- Comparing to global average sales
ORDER BY 
    total_sales DESC
LIMIT 100;
