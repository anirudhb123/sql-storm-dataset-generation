
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price, 
        COALESCE(ws.ws_net_paid, 0) AS net_paid, 
        1 AS level
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_sales_price, 
        COALESCE(cs.cs_net_paid, 0) AS net_paid, 
        sh.level + 1
    FROM sales_hierarchy sh
    JOIN catalog_sales cs ON sh.c_customer_sk = cs.cs_bill_customer_sk
    WHERE cs.cs_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)

SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(sh.net_paid) AS total_net_sales,
    COUNT(DISTINCT sh.level) AS purchase_levels,
    COUNT(DISTINCT CASE WHEN sh.level = 1 THEN sh.c_customer_sk END) AS web_customers,
    COUNT(DISTINCT CASE WHEN sh.level > 1 THEN sh.c_customer_sk END) AS catalog_customers
FROM sales_hierarchy sh
JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
GROUP BY c.c_first_name, c.c_last_name
HAVING SUM(sh.net_paid) > (
    SELECT AVG(total) FROM (
        SELECT 
            SUM(ws.ws_net_paid) AS total 
        FROM web_sales ws 
        GROUP BY ws.ws_bill_customer_sk
    ) AS avg_sales
)
ORDER BY total_net_sales DESC
LIMIT 10;

