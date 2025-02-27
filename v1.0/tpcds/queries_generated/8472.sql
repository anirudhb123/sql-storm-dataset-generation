
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
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
        web_site_id, 
        total_profit,
        total_orders,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        RankedSales rs
    JOIN 
        web_site w ON rs.web_site_sk = w.web_site_sk
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_profit,
    tw.total_orders
FROM 
    TopWebsites tw
JOIN 
    web_site w ON tw.web_site_id = w.web_site_id
WHERE 
    tw.profit_rank <= 10
ORDER BY 
    tw.total_profit DESC;
