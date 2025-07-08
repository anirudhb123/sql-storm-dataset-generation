
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_net_profit
    FROM 
        RecursiveSales
    WHERE 
        rank <= 10
), 
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        ti.total_quantity,
        ti.total_net_profit,
        CASE 
            WHEN ti.total_net_profit IS NULL THEN 'Unknown Profit'
            ELSE CONCAT('$', CAST(ti.total_net_profit AS CHAR(15)))
        END AS formatted_profit,
        ti.ws_item_sk
    FROM 
        TopItems ti
    JOIN 
        item i ON ti.ws_item_sk = i.i_item_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    id.total_quantity,
    id.formatted_profit,
    d.d_day_name,
    d.d_month_seq,
    d.d_year
FROM 
    ItemDetails id
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = id.ws_item_sk)
WHERE 
    d.d_year = (SELECT MAX(d_year) FROM date_dim)
ORDER BY 
    id.total_net_profit DESC
FETCH FIRST 5 ROWS ONLY;
