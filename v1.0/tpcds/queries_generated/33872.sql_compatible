
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        0 AS level
    FROM web_sales ws
    GROUP BY ws.web_site_sk, ws.web_name
    
    UNION ALL
    
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) + s.total_sales AS total_sales,
        level + 1
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN SalesCTE s ON s.web_site_sk = ws.ws_web_site_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, s.total_sales, level
)
SELECT 
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    MAX(ws.total_sales) AS max_website_sales,
    ARRAY_AGG(DISTINCT ws.web_name) AS associated_websites
FROM customer_address ca
LEFT JOIN store s ON ca.ca_address_sk = s.s_addr_sk
LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN SalesCTE ws ON ws.web_site_sk = c.c_current_cdemo_sk
WHERE ca.ca_state = 'CA'
AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY ca.ca_city
HAVING SUM(ss.ss_ext_sales_price) > (
    SELECT AVG(total_sales) 
    FROM (
        SELECT SUM(ss2.ss_ext_sales_price) AS total_sales
        FROM store_sales ss2
        GROUP BY ss2.ss_store_sk
    ) AS avg_sales
)
ORDER BY total_store_sales DESC
LIMIT 10;
