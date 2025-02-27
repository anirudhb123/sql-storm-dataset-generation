
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS Total_Net_Profit, 
        COUNT(DISTINCT ws_order_number) AS Order_Count
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) + Total_Net_Profit AS Total_Net_Profit, 
        Order_Count + COUNT(DISTINCT cs_order_number) AS Order_Count
    FROM catalog_sales
    INNER JOIN SalesCTE ON cs_item_sk = SalesCTE.ws_item_sk
    GROUP BY cs_item_sk, Total_Net_Profit, Order_Count
),
RankedSales AS (
    SELECT 
        ws_item_sk, 
        Total_Net_Profit, 
        Order_Count,
        RANK() OVER (ORDER BY Total_Net_Profit DESC) AS Rank
    FROM SalesCTE
),
StoreInfo AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        SUM(ss_ext_sales_price) AS Total_Sales
    FROM store_sales
    GROUP BY s_store_sk, s_store_name
)
SELECT 
    si.s_store_name, 
    si.Total_Sales, 
    rs.ws_item_sk, 
    rs.Total_Net_Profit, 
    rs.Order_Count 
FROM RankedSales rs
LEFT JOIN StoreInfo si ON rs.ws_item_sk IN (
    SELECT ws_item_sk 
    FROM web_sales 
    WHERE ws_sales_price > (SELECT AVG(ws_net_profit) FROM web_sales)
)
WHERE rs.Rank <= 10
ORDER BY si.Total_Sales DESC, rs.Total_Net_Profit DESC;
