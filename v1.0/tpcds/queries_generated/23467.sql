
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY ws.ws_item_sk) AS UniqueCustomers
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.PriceRank,
        rs.TotalQuantity,
        rs.UniqueCustomers
    FROM 
        RankedSales rs
    WHERE 
        (rs.TotalQuantity > 100 AND rs.PriceRank <= 3)
        OR (rs.UniqueCustomers > 5 AND rs.ws_sales_price < 20)
),
InventoryLevels AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS AvgInventory,
        MAX(inv.inv_quantity_on_hand) AS MaxInventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
WebReturnsAnalysis AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturns,
        COUNT(*) AS ReturnCount,
        AVG(wr.wr_return_amt) AS AvgReturnAmt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_sales_price,
    fs.ws_quantity,
    il.AvgInventory,
    il.MaxInventory,
    wra.TotalReturns,
    wra.ReturnCount,
    wra.AvgReturnAmt
FROM 
    FilteredSales fs
JOIN 
    InventoryLevels il ON fs.ws_item_sk = il.inv_item_sk
LEFT JOIN 
    WebReturnsAnalysis wra ON fs.ws_item_sk = wra.wr_item_sk
WHERE 
    (fs.ws_sales_price - COALESCE(wra.AvgReturnAmt, 0)) > 0
    AND il.AvgInventory IS NOT NULL
ORDER BY 
    fs.ws_sales_price DESC, fs.ws_order_number
LIMIT 100 OFFSET 50;
