
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        s_manager,
        s_market_desc,
        s_number_employees,
        s_floor_space,
        s_country,
        1 AS level
    FROM 
        store
    WHERE 
        s_country = 'USA'
    
    UNION ALL
    
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        s.s_manager,
        s.s_market_desc,
        s.s_number_employees,
        s.s_floor_space,
        s.s_country,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_manager = sh.s_manager
)
SELECT 
    sh.s_store_name,
    sh.s_manager,
    sh.s_market_desc,
    sh.s_number_employees,
    sh.s_floor_space,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(ws.ws_order_number) AS total_web_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_net_paid) AS max_net_paid,
    CASE 
        WHEN COUNT(ws.ws_order_number) > 0 THEN 
            SUM(ws.ws_net_paid) / COUNT(ws.ws_order_number) 
        ELSE 
            0 
    END AS avg_net_per_order
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_sales ss ON sh.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    web_sales ws ON sh.s_store_sk = ws.ws_warehouse_sk
WHERE 
    sh.level > 1
    AND sh.s_number_employees IS NOT NULL
GROUP BY 
    sh.s_store_name, sh.s_manager, sh.s_market_desc, sh.s_number_employees, sh.s_floor_space
ORDER BY 
    total_net_profit DESC
LIMIT 10
OFFSET 5;
