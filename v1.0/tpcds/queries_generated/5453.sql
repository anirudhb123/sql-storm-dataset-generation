
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    t.web_site_id,
    t.total_net_profit,
    t.total_orders,
    ROUND(t.total_net_profit / NULLIF(t.total_orders, 0), 2) AS avg_net_profit_per_order,
    w.web_name,
    w.web_city,
    w.web_state
FROM 
    TopWebSites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
ORDER BY 
    t.total_net_profit DESC;
