
WITH RECURSIVE cte_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) + cte_sales.total_net_profit AS total_net_profit,
        level + 1
    FROM 
        catalog_sales cs
    JOIN cte_sales ON cs_item_sk = cte_sales.ws_item_sk
    GROUP BY 
        cs_item_sk
),
filtered_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_net_profit
    FROM 
        item
    JOIN 
        cte_sales sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.total_net_profit > 1000
)
SELECT 
    f.item_id,
    f.item_desc,
    f.total_net_profit,
    COALESCE((SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = f.item_id), 0) AS store_sales_count,
    COALESCE((SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = f.item_id AND wr.wr_return_amt > 0), 0) AS return_count,
    ROW_NUMBER() OVER (ORDER BY f.total_net_profit DESC) AS rank
FROM 
    filtered_sales f
ORDER BY 
    f.total_net_profit DESC
LIMIT 10;
