
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 AND 
        ws.ws_net_profit IS NOT NULL 
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS Total_Quantity_Sold,
        COUNT(DISTINCT ws.ws_order_number) AS Unique_Orders,
        AVG(ws.ws_sales_price) AS Avg_Sales_Price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 3
)
SELECT 
    ss.i_item_id,
    ss.Total_Quantity_Sold,
    ss.Unique_Orders,
    ss.Avg_Sales_Price,
    COALESCE(hp.ws_net_profit, 0) AS Top_Profit_Net
FROM 
    SalesSummary ss
LEFT JOIN 
    HighProfitItems hp ON ss.i_item_id = hp.ws_item_sk
WHERE 
    ss.Total_Quantity_Sold > 10
ORDER BY 
    ss.Avg_Sales_Price DESC,
    Top_Profit_Net DESC
LIMIT 10
OFFSET 5;
