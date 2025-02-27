
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500

    UNION ALL

    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity + COALESCE(ss.ws_quantity, 0),
        ws_net_profit + COALESCE(ss.ws_net_profit, 0),
        level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_summary ss ON ws.order_number = ss.ws_order_number AND ss.level < 5
)
, customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity,
        c.c_first_name,
        c.c_last_name
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ca.ca_city,
    cs.total_orders, 
    cs.total_profit, 
    cs.avg_quantity,
    COALESCE(SUM(ss.ws_net_profit), 0) AS recursive_profit,
    MAX(CASE WHEN cs.avg_quantity IS NULL THEN 'No Orders' ELSE 'Orders Found' END) AS order_status
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_summary cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk = cs.ws_item_sk
GROUP BY 
    ca.ca_city, cs.total_orders, cs.total_profit, cs.avg_quantity
HAVING 
    SUM(cs.total_profit) > 1000 OR COUNT(cs.total_orders) IS NULL
ORDER BY 
    ca.ca_city ASC, recursive_profit DESC
LIMIT 10;
