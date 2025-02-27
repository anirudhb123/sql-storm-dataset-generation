
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        s_number_employees, 
        s_floor_space, 
        s_manager,
        1 AS level
    FROM store
    WHERE s_state = 'CA'
    
    UNION ALL
    
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        s.s_number_employees, 
        s.s_floor_space, 
        s.s_manager,
        sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_name
), total_sales AS (
    SELECT 
        ws_store_sk, 
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_store_sk
), avg_sales AS (
    SELECT 
        ws_store_sk,
        AVG(total_profit) AS avg_profit,
        AVG(total_revenue) AS avg_revenue,
        AVG(total_orders) AS avg_orders
    FROM total_sales
)
SELECT 
    sh.s_store_name,
    sh.s_number_employees,
    sh.s_floor_space,
    sh.level,
    coalesce(ts.total_profit, 0) AS total_profit,
    coalesce(ts.total_revenue, 0) AS total_revenue,
    coalesce(ts.total_orders, 0) AS total_orders,
    ads.avg_profit,
    ads.avg_revenue,
    ads.avg_orders
FROM sales_hierarchy sh
LEFT JOIN total_sales ts ON sh.s_store_sk = ts.ws_store_sk
JOIN avg_sales ads ON sh.s_store_sk = ads.ws_store_sk
WHERE 
    (sh.level = 1 OR ts.total_profit > ads.avg_profit * 1.5) AND
    (sh.s_number_employees IS NOT NULL AND sh.s_number_employees > 10)
ORDER BY total_profit DESC;
