
WITH aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        d_year AS sale_year
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_item_sk, d_year
),
top_items AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY sale_year ORDER BY total_profit DESC) AS profit_rank
    FROM 
        aggregated_sales
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    dd.d_year
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    date_dim dd ON dd.d_year = ti.sale_year
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    dd.d_year, ti.total_profit DESC;
