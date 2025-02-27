
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_item_sk
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        AVG(i.i_current_price) AS avg_price,
        MAX(i.i_current_price) AS max_price,
        MIN(i.i_current_price) AS min_price
    FROM 
        item i
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    r.web_site_sk,
    r.ws_item_sk,
    i.id_item_id,
    r.total_quantity,
    r.total_revenue,
    s.s_store_id AS most_profitable_store,
    s.ss_net_profit AS max_profit_store,
    i.avg_price,
    i.max_price,
    i.min_price
FROM 
    ranked_sales r
JOIN 
    item_stats i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_sales s ON r.ws_item_sk = s.ss_item_sk
WHERE 
    r.revenue_rank = 1
    AND s.ss_net_profit = (
        SELECT MAX(ss_net_profit) 
        FROM store_sales 
        WHERE ss_item_sk = r.ws_item_sk
    )
ORDER BY 
    r.web_site_sk, r.total_revenue DESC;
