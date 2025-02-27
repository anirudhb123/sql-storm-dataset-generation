
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
), 
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_size,
        i.i_color,
        COALESCE((SELECT MAX(ws.ws_net_paid) 
                  FROM web_sales ws 
                  WHERE ws.ws_item_sk = i.i_item_sk), 0) AS MaxNetPaid
    FROM 
        item i
), 
SalesSummary AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        SUM(rs.ws_net_profit) AS TotalNetProfit,
        AVG(id.i_current_price) AS AvgCurrentPrice,
        COUNT(rs.ws_order_number) AS OrderCount
    FROM 
        ItemDetails id
    LEFT JOIN 
        RankedSales rs ON id.i_item_id = rs.ws_item_sk
    GROUP BY 
        id.i_item_id, id.i_product_name
)

SELECT 
    ss.i_item_id,
    ss.i_product_name,
    ss.TotalNetProfit,
    ss.AvgCurrentPrice,
    ss.OrderCount,
    CASE 
        WHEN ss.TotalNetProfit > 1000 THEN 'High Profit'
        WHEN ss.TotalNetProfit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS ProfitCategory,
    CASE 
        WHEN ss.OrderCount = 0 THEN 'No Orders'
        ELSE CAST(ROUND((ss.TotalNetProfit / NULLIF(ss.OrderCount, 0)), 2) AS varchar)
    END AS AvgProfitPerOrder
FROM 
    SalesSummary ss
WHERE 
    ss.TotalNetProfit IS NOT NULL
ORDER BY 
    ss.TotalNetProfit DESC
FETCH FIRST 10 ROWS ONLY;
