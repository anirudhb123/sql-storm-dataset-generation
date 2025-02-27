
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS TotalProfit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_quantity > 0
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.TotalProfit
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 5
        AND rs.TotalProfit > 1000
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturnQty,
        SUM(sr_return_amt) AS TotalReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
WebReturnMetrics AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS WebTotalReturnQty,
        SUM(wr.wr_return_amt) AS WebTotalReturnAmt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk 
)
SELECT 
    f.ws_item_sk AS Item_SK,
    COALESCE(f.ws_order_number, 'N/A') AS Order_Number,
    f.ws_sales_price AS Sales_Price,
    f.ws_quantity AS Quantity,
    COALESCE(tr.TotalReturnQty, 0) AS Total_Return_Qty,
    COALESCE(tr.TotalReturnAmt, 0) AS Total_Return_Amt,
    r.TotalProfit AS Total_Profit
FROM 
    FilteredSales f
LEFT JOIN 
    TotalReturns tr ON f.ws_item_sk = tr.sr_item_sk
LEFT JOIN 
    WebReturnMetrics wrm ON f.ws_item_sk = wrm.wr_item_sk
WHERE 
    (f.ws_sales_price > 50 OR f.ws_quantity < 5)
    AND (f.TotalProfit BETWEEN 1000 AND 5000 OR f.TotalProfit IS NULL)
ORDER BY 
    f.TotalProfit DESC, f.ws_sales_price;
