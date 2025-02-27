
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ARRAY[c.c_first_name || ' ' || c.c_last_name] AS full_name_path,
        1 AS level
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ch.full_name_path || (c.c_first_name || ' ' || c.c_last_name),
        ch.level + 1
    FROM 
        customer_hierarchy AS ch
    JOIN 
        customer AS c ON c.c_current_cdemo_sk = ch.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
)
SELECT 
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cs.cs_sales_price) AS average_catalog_sales,
    COUNT(DISTINCT ch.c_customer_sk) AS female_customers
FROM 
    customer_address AS ca
LEFT JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
FULL OUTER JOIN 
    catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN 
    customer_hierarchy AS ch ON ch.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ws.ws_sales_price IS NOT NULL OR cs.cs_sales_price IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(ch.c_customer_sk) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
