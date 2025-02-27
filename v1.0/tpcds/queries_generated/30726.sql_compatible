
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_sales + COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON c.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales, sh.level
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales,
    CASE
        WHEN sh.total_sales = 0 THEN 'No Sales'
        WHEN sh.total_sales < 100 THEN 'Low Sales'
        WHEN sh.total_sales BETWEEN 100 AND 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    sales_hierarchy sh
LEFT JOIN 
    customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    sh.total_sales DESC
LIMIT 50;
