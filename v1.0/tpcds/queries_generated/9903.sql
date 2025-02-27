
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        r.web_site_sk,
        r.total_quantity,
        r.total_sales,
        r.total_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    t.total_quantity,
    t.total_sales,
    t.total_profit
FROM 
    TopWebSites t
JOIN 
    web_site w ON t.web_site_sk = w.web_site_sk
ORDER BY 
    t.total_profit DESC;
