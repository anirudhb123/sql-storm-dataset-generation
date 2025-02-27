
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        1 AS level
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    UNION ALL
    SELECT 
        ws_item_sk,
        ss.total_quantity + ws.quantity AS total_quantity,
        ss.total_profit + ws.net_profit AS total_profit,
        2 AS level
    FROM 
        sales_summary ss
    JOIN 
        web_sales ws ON ss.cs_item_sk = ws.ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ss.total_quantity,
        ss.total_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS rn
    FROM 
        sales_summary ss
    JOIN 
        item ON ss.cs_item_sk = item.i_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    CASE 
        WHEN ti.total_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: $', ROUND(ti.total_profit, 2))
    END AS profit_status,
    COALESCE(CAST(ti.total_quantity AS VARCHAR), '0') AS quantity_status
FROM 
    top_items ti
WHERE 
    ti.rn <= 10
ORDER BY 
    ti.total_profit DESC
LIMIT 5
OFFSET 2;
