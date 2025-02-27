
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_quantity) DESC) AS rank_by_quantity
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.web_site_id, ws.net_profit
)
SELECT 
    s.web_site_id,
    s.total_quantity,
    s.avg_net_paid,
    s.total_orders,
    COALESCE(s.net_profit, 0) AS net_profit,
    r.r_reason_desc AS return_reason,
    r.r_reason_sk
FROM 
    sales_data s
LEFT JOIN 
    web_returns wr ON s.web_site_id = (SELECT w.web_site_id FROM web_site w WHERE w.web_site_sk = wr.wr_web_page_sk LIMIT 1)
LEFT JOIN 
    reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE 
    s.rank_by_quantity <= 5
ORDER BY 
    s.total_quantity DESC;
