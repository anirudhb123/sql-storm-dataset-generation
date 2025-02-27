
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_order_number
)
SELECT 
    ts.ws_order_number,
    ts.total_quantity,
    ts.total_net_profit,
    ca.ca_city,
    ca.ca_state
FROM 
    TopSales ts
LEFT JOIN 
    store s ON ts.ws_order_number = s.s_store_id
LEFT JOIN 
    customer_address ca ON s.s_store_sk = ca.ca_address_sk
WHERE 
    ts.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM TopSales
    )
ORDER BY 
    ts.total_net_profit DESC
LIMIT 10;
