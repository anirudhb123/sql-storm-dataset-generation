
WITH RECURSIVE cte_sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
most_profitable_items AS (
    SELECT 
        itt.i_item_id,
        cte.total_net_profit,
        cte.total_orders
    FROM 
        cte_sales_summary cte
    JOIN 
        item itt ON cte.ws_item_sk = itt.i_item_sk
    WHERE 
        cte.rn <= 10
)
SELECT 
    a.ca_city AS address_city,
    SUM(mp.total_net_profit) AS city_total_net_profit,
    COUNT(DISTINCT mp.i_item_id) AS distinct_items_sold
FROM 
    most_profitable_items mp
JOIN 
    store_sales ss ON mp.total_orders = ss.ss_ticket_number
JOIN 
    customer c ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
GROUP BY 
    a.ca_city
HAVING 
    SUM(mp.total_net_profit) > 1000.00
ORDER BY 
    city_total_net_profit DESC
LIMIT 5
UNION ALL
SELECT 
    NULL AS address_city,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    web_sales ws
WHERE 
    ws.ws_ship_date_sk IS NOT NULL 
    AND ws.ws_net_profit IS NOT NULL
    AND ws.ws_net_profit < 0;
