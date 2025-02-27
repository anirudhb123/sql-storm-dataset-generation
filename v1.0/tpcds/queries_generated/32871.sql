
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        1 AS level
    FROM 
        customer 
    WHERE 
        c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        wr_returning_customer_sk AS c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1
    FROM 
        web_returns wr 
    JOIN 
        customer c ON wr_returning_customer_sk = c.c_customer_sk
    JOIN 
        SalesHierarchy sh ON wr_returned_date_sk = sh.c_customer_sk
)

SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ws.ws_net_profit) AS total_web_sales,
    SUM(cs.cs_net_profit) AS total_catalog_sales,
    SUM(ss.ss_net_profit) AS total_store_sales,
    DENSE_RANK() OVER (PARTITION BY a.ca_state ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_id) > 0 THEN 
            (SUM(ws.ws_net_profit) + SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) / COUNT(DISTINCT c.c_customer_id)
        ELSE 
            NULL 
    END AS avg_sales_per_customer
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    total_web_sales > 5000 OR total_catalog_sales > 3000
ORDER BY 
    avg_sales_per_customer DESC;
