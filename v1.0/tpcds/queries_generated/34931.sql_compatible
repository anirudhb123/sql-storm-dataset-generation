
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ws.ws_order_number, 
        ws.ws_ship_date_sk, 
        ws.ws_net_profit, 
        1 AS level
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_net_profit > 0
    
    UNION ALL
    
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ws.ws_order_number, 
        ws.ws_ship_date_sk, 
        ws.ws_net_profit + sh.ws_net_profit AS total_net_profit,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        web_sales ws ON sh.ws_order_number = ws.ws_order_number
    JOIN 
        customer c ON sh.c_customer_id = c.c_customer_id
    WHERE 
        ws.ws_net_profit IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT sh.c_customer_id) AS distinct_customers,
    SUM(sh.ws_net_profit) AS total_profit,
    AVG(sh.ws_net_profit) AS average_profit_per_customer,
    MAX(sh.level) AS max_sales_level,
    MIN(sh.level) AS min_sales_level
FROM 
    SalesHierarchy sh
LEFT JOIN 
    customer_address ca ON sh.c_customer_id = ca.ca_address_id
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT sh.c_customer_id) > 5
ORDER BY 
    total_profit DESC
LIMIT 10
OFFSET 5;
