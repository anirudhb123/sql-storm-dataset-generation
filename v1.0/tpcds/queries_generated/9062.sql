
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 
        AND dd.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        ws.web_site_sk
),
top_websites AS (
    SELECT 
        w.warehouse_id,
        rw.total_profit
    FROM 
        ranked_sales rw
    JOIN 
        warehouse w ON rw.web_site_sk = w.w_warehouse_sk
    WHERE 
        rw.profit_rank <= 10
)
SELECT 
    w.warehouse_name,
    w.w_city,
    tw.total_profit
FROM 
    top_websites tw
JOIN 
    warehouse w ON tw.warehouse_id = w.w_warehouse_id
ORDER BY 
    tw.total_profit DESC
LIMIT 5;
