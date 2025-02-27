
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20230331
),
TopProfitableItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        i.i_item_desc,
        COUNT(DISTINCT r.ws_order_number) AS order_count
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rn = 1
    GROUP BY 
        r.ws_item_sk, r.ws_order_number, r.ws_net_profit, i.i_item_desc 
),
AggregateSales AS (
    SELECT 
        ti.ws_item_sk,
        SUM(ti.ws_net_profit) AS total_net_profit,
        AVG(ti.ws_net_profit) AS avg_net_profit,
        COUNT(ti.order_count) AS unique_orders
    FROM 
        TopProfitableItems ti
    GROUP BY 
        ti.ws_item_sk
)
SELECT 
    a.ws_item_sk,
    a.total_net_profit,
    a.avg_net_profit,
    a.unique_orders,
    COALESCE(i.i_brand, 'Unknown') AS item_brand,
    CASE 
        WHEN a.avg_net_profit IS NULL THEN 'No Profit'
        WHEN a.avg_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    AggregateSales a
LEFT JOIN 
    item i ON a.ws_item_sk = i.i_item_sk
WHERE 
    a.total_net_profit > 1000
ORDER BY 
    a.total_net_profit DESC
LIMIT 10
UNION ALL
SELECT 
    i.i_item_sk,
    AVG(ws.ws_net_profit) AS total_net_profit,
    NULL AS avg_net_profit,
    COUNT(ws.ws_order_number) AS unique_orders,
    COALESCE(i.i_brand, 'Unknown') AS item_brand,
    'No Profit' AS profit_status
FROM 
    item i
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
WHERE 
    ws.ws_sold_date_sk IS NULL
GROUP BY 
    i.i_item_sk, i.i_brand
HAVING 
    COUNT(ws.ws_order_number) < 10
ORDER BY 
    total_net_profit DESC;
