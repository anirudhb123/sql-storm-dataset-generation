
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        r.web_site_sk,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 5
)
SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT('WebSite:', w.web_site_id), ', ') AS associated_websites
FROM 
    warehouse w
LEFT JOIN 
    web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN 
    TopWebsites tw ON ws.ws_web_site_sk = tw.web_site_sk
GROUP BY 
    w.w_warehouse_name
HAVING 
    SUM(ws.ws_net_profit) > 10000 OR SUM(ws.ws_quantity) IS NULL
ORDER BY 
    total_net_profit DESC;
