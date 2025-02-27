
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk AS SaleDate,
        w.w_warehouse_id AS WarehouseID,
        i.i_item_id AS ItemID,
        SUM(ws.ws_quantity) AS TotalQuantity,
        SUM(ws.ws_net_profit) AS TotalProfit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.ws_sold_date_sk, w.w_warehouse_id, i.i_item_id
),
ProfitByMonth AS (
    SELECT 
        DATE_TRUNC('month', TO_DATE(CAST(SaleDate AS TEXT), 'YYYYMMDD')) AS SaleMonth,
        WarehouseID,
        SUM(TotalQuantity) AS MonthlyQuantity,
        SUM(TotalProfit) AS MonthlyProfit
    FROM SalesData
    GROUP BY SaleMonth, WarehouseID
),
RankedProfit AS (
    SELECT 
        SaleMonth,
        WarehouseID,
        MonthlyQuantity,
        MonthlyProfit,
        RANK() OVER (PARTITION BY SaleMonth ORDER BY MonthlyProfit DESC) AS ProfitRank
    FROM ProfitByMonth
)
SELECT 
    SaleMonth,
    WarehouseID,
    MonthlyQuantity,
    MonthlyProfit
FROM RankedProfit
WHERE ProfitRank <= 5
ORDER BY SaleMonth, MonthlyProfit DESC;
