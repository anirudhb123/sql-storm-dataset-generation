
WITH RECURSIVE sales_path AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_ext_sales_price,
        sp.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_path sp ON cs_item_sk = sp.ws_item_sk
    WHERE 
        cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    AVG(ws_ext_sales_price) AS avg_web_sale,
    MAX(ws_ext_sales_price) AS max_web_sale,
    SUM(NULLIF(cs_ext_sales_price * 0.9, 0)) AS adjusted_catalog_sales,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM 
    sales_path sp
JOIN 
    customer c ON sp.ws_order_number = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON sp.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    catalog_sales cs ON sp.ws_item_sk = cs.cs_item_sk
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    total_web_sales DESC;
