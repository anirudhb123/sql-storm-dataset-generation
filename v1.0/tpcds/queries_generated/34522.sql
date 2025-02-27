
WITH RECURSIVE employee_hierarchy AS (
    SELECT cc_manager AS manager_id, cc_call_center_sk AS employee_id, 1 AS level
    FROM call_center
    WHERE cc_manager IS NOT NULL
    UNION ALL
    SELECT c.cc_manager, e.employee_id, eh.level + 1
    FROM call_center c
    JOIN employee_hierarchy eh ON c.cc_call_center_sk = eh.manager_id
)
SELECT 
    s.s_store_name,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High Sales'
        WHEN SUM(ws.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store s ON ws.ws_warehouse_sk = s.s_store_sk
LEFT JOIN 
    employee_hierarchy eh ON s.s_manager = eh.employee_id
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND (ws.ws_ext_discount_amt IS NULL OR ws.ws_ext_discount_amt < 50)
GROUP BY 
    s.s_store_name, ca.ca_city
HAVING 
    total_sales > 500
ORDER BY 
    total_sales DESC;
