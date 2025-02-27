
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = 20220101
    
    UNION ALL
    
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit + sc.ws_net_profit,
        level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_cte sc ON ws.ws_order_number = sc.ws_order_number 
    WHERE 
        ws_sold_date_sk = 20220101 AND level < 5
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS customer_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.total_net_profit > 0
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.order_count,
    nvl(sm.sm_type, 'Unknown') AS ship_mode,
    inv.inv_quantity_on_hand,
    CASE
        WHEN tc.order_count > 10 THEN 'Premium'
        ELSE 'Standard'
    END AS customer_type
FROM 
    top_customers tc
LEFT JOIN 
    store s ON tc.total_net_profit > 10000 AND s.s_country = 'USA'
LEFT JOIN 
    inventory inv ON s.s_store_sk = inv.inv_warehouse_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT DISTINCT ws.ws_ship_mode_sk FROM web_sales ws WHERE ws.ws_order_number = tc.c_customer_id)
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
