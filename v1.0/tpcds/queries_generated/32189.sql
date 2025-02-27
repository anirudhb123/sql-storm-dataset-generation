
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_sales_price,
        1 AS level
    FROM 
        store s
    WHERE 
        s_number_employees > (SELECT AVG(s_number_employees) FROM store)

    UNION ALL

    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_sales_price,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE 
        sh.level < 3
)

SELECT 
    ca_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(SUM(ws_sales_price)) OVER (PARTITION BY ca_state) AS avg_sales_per_state,
    MAX(cd_purchase_estimate) AS highest_purchase_estimate
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.s_store_sk = ws.ws_warehouse_sk
WHERE 
    ca_state IS NOT NULL 
    AND (cd_purchase_estimate IS NOT NULL AND cd_purchase_estimate > 0)
    AND sh.level = 1 
GROUP BY 
    ca_state
HAVING 
    total_customers > 50 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
