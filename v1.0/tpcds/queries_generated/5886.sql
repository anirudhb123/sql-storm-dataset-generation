
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_moy IN (5, 6)
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
),
TotalSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        TopWebSites tws ON ws.ws_web_site_sk = tws.web_site_id
    GROUP BY 
        ws.web_site_id
)
SELECT 
    tws.web_site_id,
    tws.total_net_profit,
    ts.total_orders,
    ts.total_quantity_sold
FROM 
    TopWebSites tws
JOIN 
    TotalSales ts ON tws.web_site_id = ts.web_site_id
ORDER BY 
    tws.total_net_profit DESC;
