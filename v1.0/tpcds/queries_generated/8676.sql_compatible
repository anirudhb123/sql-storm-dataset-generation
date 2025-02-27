
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.sold_date_sk,
        SUM(ws.net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.sold_date_sk
),
TopSites AS (
    SELECT 
        web_site_sk,
        SUM(total_net_profit) AS overall_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    ws.web_site_id,
    ws.web_name,
    ts.overall_net_profit
FROM 
    web_site ws
JOIN 
    TopSites ts ON ws.web_site_sk = ts.web_site_sk
ORDER BY 
    ts.overall_net_profit DESC;
