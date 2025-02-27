
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
TopSales AS (
    SELECT 
        item_sk,
        total_quantity,
        total_net_profit
    FROM 
        SalesData
    WHERE 
        rank_profit <= 10
), 
StoreData AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(sd.store_net_profit, 0) AS total_store_net_profit,
    COALESCE(sd.store_quantity, 0) AS total_store_quantity,
    COALESCE(td.total_net_profit, 0) AS total_top_sales_net_profit,
    COALESCE(td.total_quantity, 0) AS total_top_sales_quantity
FROM 
    store s
LEFT JOIN 
    StoreData sd ON s.s_store_sk = sd.ss_store_sk
LEFT JOIN 
    TopSales td ON td.item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = '2023-10-01'
    )
WHERE 
    sd.store_net_profit IS NOT NULL 
ORDER BY 
    total_store_net_profit DESC;
