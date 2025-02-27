
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
item_promotions AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        p.p_promo_name,
        COALESCE(SUM(ws.net_profit), 0) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, 
        i.i_item_id, 
        p.p_promo_name
),
top_items AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit,
        i.i_item_id,
        ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS item_rank
    FROM 
        sales_summary s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.total_quantity > 0
)
SELECT 
    ti.item_rank,
    ti.i_item_id,
    ti.total_quantity,
    ti.total_profit,
    ip.p_promo_name,
    CASE 
        WHEN ti.total_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: ', ROUND(ti.total_profit, 2))
    END AS profit_statement
FROM 
    top_items ti
LEFT JOIN 
    item_promotions ip ON ti.ws_item_sk = ip.i_item_sk
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_profit DESC;
