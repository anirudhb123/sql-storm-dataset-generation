
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
Aggregate_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_profit,
        AVG(s.ws_sales_price) AS avg_sales_price
    FROM 
        Sales_CTE s
    INNER JOIN 
        item ON s.ws_item_sk = item.i_item_sk
    WHERE 
        s.rnk <= 5
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
Top_Stores AS (
    SELECT 
        store.s_store_id,
        SUM(ss.net_profit) AS store_profit
    FROM 
        store_sales ss
    INNER JOIN 
        store ON ss.ss_store_sk = store.s_store_sk
    GROUP BY 
        store.s_store_id
)
SELECT 
    a.i_item_id, 
    a.i_item_desc, 
    a.total_quantity, 
    a.total_profit, 
    a.avg_sales_price,
    s.s_store_id,
    s.store_profit,
    CASE 
        WHEN a.total_profit IS NULL THEN 'No Sales'
        WHEN s.store_profit IS NULL THEN 'Store Not Found'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    Aggregate_Sales a
LEFT JOIN 
    Top_Stores s ON a.total_profit > 1000000
ORDER BY 
    a.total_profit DESC, 
    s.store_profit DESC;
