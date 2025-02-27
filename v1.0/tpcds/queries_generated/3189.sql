
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) as rank_profit,
        COUNT(*) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        customer_id,
        total_net_profit,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        total_net_profit > (
            SELECT 
                AVG(total_net_profit) 
            FROM 
                ranked_sales
        )
)
SELECT 
    hvc.customer_id, 
    hvc.total_net_profit, 
    hvc.total_orders, 
    ca.ca_city,
    ca.ca_state,
    COALESCE(sm.sm_carrier, 'Standard') AS shipping_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_address ca ON hvc.customer_id = ca.ca_address_id
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = hvc.customer_id)
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    hvc.customer_id, hvc.total_net_profit, hvc.total_orders, ca.ca_city, ca.ca_state, sm.sm_carrier
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    hvc.total_net_profit DESC
LIMIT 10;
