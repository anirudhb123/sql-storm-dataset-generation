
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
top_websites AS (
    SELECT 
        web_site_sk,
        total_quantity,
        total_sales,
        avg_net_profit
    FROM 
        ranked_sales
    WHERE 
        rank_sales <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    t.total_quantity,
    t.total_sales,
    t.avg_net_profit
FROM 
    top_websites t
JOIN 
    web_site w ON t.web_site_sk = w.web_site_sk
ORDER BY 
    t.total_sales DESC;
