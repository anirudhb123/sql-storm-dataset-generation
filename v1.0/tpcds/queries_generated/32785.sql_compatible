
WITH RECURSIVE CTE_SALES AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
SALES_SUMMARY AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS total_orders
    FROM 
        CTE_SALES
    GROUP BY 
        ws_item_sk
),
ADDRESS_COUNTS AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    ac.customer_count,
    ss.total_net_profit,
    ss.avg_sales_price,
    (SELECT 
        SUM(ws_quantity)
     FROM 
        web_sales ws
     WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM CTE_SALES)
    ) AS total_quantity_sold,
    (CASE 
        WHEN ss.total_orders > 0 THEN 
            ROUND(ss.total_net_profit / ss.total_orders, 2) 
        ELSE 0 
     END) AS avg_profit_per_order
FROM 
    ADDRESS_COUNTS ac
LEFT JOIN 
    SALES_SUMMARY ss ON EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM CTE_SALES)
        AND ac.customer_count > 0
    )
JOIN 
    customer_address a ON a.ca_state = ac.ca_state
WHERE 
    ac.customer_count > 100
ORDER BY 
    a.ca_state ASC;
