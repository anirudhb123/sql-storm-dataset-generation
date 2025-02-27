
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.web_open_date_sk,
        ws.web_close_date_sk,
        ws.web_url,
        ws.web_class,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.web_open_date_sk) as rn
    FROM 
        web_site ws
    WHERE 
        ws.web_open_date_sk IS NOT NULL
    UNION ALL
    SELECT 
        ws.web_site_sk,
        CONCAT(ws.web_name, ' - Subsite') AS web_name,
        ws.web_open_date_sk,
        ws.web_close_date_sk,
        NULL AS web_url,
        ws.web_class,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.web_open_date_sk) as rn
    FROM 
        web_site ws
    WHERE 
        ws.web_close_date_sk IS NULL
        AND EXISTS (SELECT 1 FROM web_page wp WHERE wp.wp_customer_sk = ws.web_site_sk)
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_net_paid) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    (SELECT COUNT(*) FROM store s WHERE s.s_zip LIKE '12345%') AS store_count,
    sales_hierarchy.web_name,
    sales_hierarchy.rn
FROM 
    customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    FULL OUTER JOIN sales_hierarchy ON sales_hierarchy.web_site_sk = ws.ws_web_site_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (ws.ws_sales_price IS NOT NULL OR ws.ws_sales_price IS NOT NULL)
GROUP BY 
    ca.ca_city, sales_hierarchy.web_name, sales_hierarchy.rn
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_sales DESC, ca.ca_city;
