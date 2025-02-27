
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL 
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rn
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
total_returns AS (
    SELECT 
        sr_item_sk AS item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
profit_summary AS (
    SELECT 
        i.ws_item_sk AS item_sk,
        ISNULL(p.total_profit, 0) AS total_profit,
        ISNULL(r.total_returns, 0) AS total_returns,
        (ISNULL(p.total_profit, 0) - ISNULL(r.total_returns, 0)) AS net_profit
    FROM 
        item_sales p
    LEFT JOIN 
        total_returns r ON p.ws_item_sk = r.item_sk
)
SELECT 
    item_sk,
    total_profit,
    total_returns,
    net_profit,
    CASE 
        WHEN net_profit > 0 THEN 'Profitable'
        WHEN net_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_status
FROM 
    profit_summary
WHERE 
    net_profit > 1000 
ORDER BY 
    net_profit DESC
LIMIT 10
OFFSET 5;
