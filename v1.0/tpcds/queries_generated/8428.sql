
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rn <= 10
)
SELECT 
    w.web_site_name,
    t.total_net_profit,
    t.total_orders,
    t.total_net_profit / NULLIF(t.total_orders, 0) AS average_profit_per_order
FROM 
    TopWebsites t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
ORDER BY 
    t.total_net_profit DESC;
