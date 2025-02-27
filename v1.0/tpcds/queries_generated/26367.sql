
WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, '; ') AS full_street_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
SalesData AS (
    SELECT 
        ws.warehouse_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON w.warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        ws.warehouse_sk, ws.ws_ship_mode_sk
),
DetailedReport AS (
    SELECT 
        ac.ca_city,
        ac.ca_state,
        sa.total_net_profit,
        sa.total_orders,
        ac.address_count,
        sa.total_net_profit / NULLIF(sa.total_orders, 0) AS avg_net_profit_per_order
    FROM 
        AddressCounts ac
    LEFT JOIN 
        SalesData sa ON ac.ca_city = sa.ca_city AND ac.ca_state = sa.ca_state
)
SELECT 
    d.ca_city,
    d.ca_state,
    d.address_count,
    d.total_orders,
    d.total_net_profit,
    d.avg_net_profit_per_order
FROM 
    DetailedReport d
WHERE 
    d.total_net_profit > 5000 
ORDER BY 
    d.total_net_profit DESC;
