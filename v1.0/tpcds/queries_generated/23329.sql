
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
SalesAnalysis AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_net_profit,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        DENSE_RANK() OVER (ORDER BY r.total_net_profit DESC) AS overall_profit_rank
    FROM 
        RankedSales r
    LEFT JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
),
TopItems AS (
    SELECT 
        sa.ws_item_sk,
        sa.item_description,
        sa.total_quantity_sold,
        sa.total_net_profit,
        (SELECT COUNT(*)
         FROM SalesAnalysis sa2 
         WHERE sa2.total_net_profit > sa.total_net_profit) AS items_more_profitable
    FROM 
        SalesAnalysis sa
    WHERE 
        sa.overall_profit_rank <= 10
)
SELECT 
    ti.item_description,
    ti.total_quantity_sold,
    ti.total_net_profit,
    ti.items_more_profitable,
    CASE 
        WHEN ti.items_more_profitable = 0 THEN 'Top Performer'
        WHEN ti.total_quantity_sold > 100 THEN 'High Volume'
        ELSE 'Average Performer'
    END AS performance_category,
    (SELECT AVG(total_net_profit) 
     FROM SalesAnalysis 
     WHERE total_net_profit IS NOT NULL) AS avg_net_profit
FROM 
    TopItems ti
WHERE 
    ti.items_more_profitable IS NOT NULL
ORDER BY 
    ti.total_net_profit DESC
LIMIT 5
OFFSET (SELECT COUNT(*)/2 FROM SalesAnalysis);
