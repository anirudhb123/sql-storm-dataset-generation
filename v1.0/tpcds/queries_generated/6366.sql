
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_moy IN (11, 12)
    GROUP BY 
        ws.web_site_sk
), highest_sales AS (
    SELECT 
        web_site_sk, 
        total_sales, 
        total_profit 
    FROM 
        ranked_sales 
    WHERE 
        rank = 1
)

SELECT 
    w.web_site_id,
    w.web_name,
    hs.total_sales,
    hs.total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
FROM 
    highest_sales hs
JOIN 
    web_site w ON hs.web_site_sk = w.web_site_sk
JOIN 
    web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
GROUP BY 
    w.web_site_id, w.web_name, hs.total_sales, hs.total_profit
ORDER BY 
    hs.total_sales DESC;
