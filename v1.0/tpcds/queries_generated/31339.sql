
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        1 AS level
    FROM 
        store s
    WHERE 
        s.s_state = 'CA'
      
    UNION ALL
    
    SELECT 
        s.s_store_id,
        s.s_store_name,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_manager = sh.s_store_id
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    RANK() OVER (PARTITION BY cu.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) IS NULL THEN 'No Sales'
        WHEN SUM(ws.ws_ext_sales_price) < 1000 THEN 'Low Sales'
        WHEN SUM(ws.ws_ext_sales_price) BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    customer cu
JOIN 
    web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.s_store_id = ws.ws_ship_addr_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
    AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    cu.c_customer_sk, cu.c_first_name, cu.c_last_name, ca.ca_city
HAVING 
    total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
