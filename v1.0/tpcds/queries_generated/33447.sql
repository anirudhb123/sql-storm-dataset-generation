
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.ca_city,
    SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_web_sales,
    SUM(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS total_catalog_sales,
    SUM(CASE WHEN ss.ss_sales_price IS NOT NULL THEN ss.ss_sales_price ELSE 0 END) AS total_store_sales,
    COUNT(DISTINCT (wr.wr_order_number)) AS total_web_returns,
    COUNT(DISTINCT (cr.cr_order_number)) AS total_catalog_returns,
    COUNT(DISTINCT (sr.sr_ticket_number)) AS total_store_returns,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_sales_price + cs.cs_sales_price + ss.ss_sales_price) DESC) AS rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    EXISTS (SELECT 1 FROM customer_hierarchy ch WHERE ch.c_customer_sk = c.c_customer_sk AND ch.level > 0)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ws.ws_sales_price + cs.cs_sales_price + ss.ss_sales_price) > 0
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
