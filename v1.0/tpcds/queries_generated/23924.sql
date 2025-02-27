
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank,
        ws_order_number,
        ws_ship_mode_sk,
        ws_web_site_sk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS ReturnCount,
        SUM(wr_return_amt) AS TotalReturnAmt
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.ws_sales_price) AS MaxSalesPrice,
        COALESCE(rs.ReturnCount, 0) AS ReturnCount,
        COALESCE(rs.TotalReturnAmt, 0) AS TotalReturnAmt,
        CASE 
            WHEN COALESCE(rs.ReturnCount, 0) > 0 THEN 'Has Returns'
            ELSE 'No Returns'
        END AS ReturnStatus
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnStats rstats ON rs.ws_item_sk = rstats.wr_item_sk
    GROUP BY 
        rs.ws_item_sk
),
FinalOutput AS (
    SELECT 
        s.ws_item_sk,
        s.MaxSalesPrice,
        s.ReturnCount,
        s.TotalReturnAmt,
        s.ReturnStatus,
        ROW_NUMBER() OVER (ORDER BY s.MaxSalesPrice DESC, s.ReturnCount) AS RowNum
    FROM 
        SalesWithReturns s
    WHERE 
        s.MaxSalesPrice > 100 OR s.ReturnCount > 10
)

SELECT 
    f.ws_item_sk,
    f.MaxSalesPrice,
    f.ReturnCount,
    f.TotalReturnAmt,
    f.ReturnStatus
FROM 
    FinalOutput f
WHERE 
    (f.ReturnStatus = 'Has Returns' AND f.ReturnCount > 5)
    OR (f.ReturnStatus = 'No Returns' AND f.MaxSalesPrice BETWEEN 150 AND 300)
ORDER BY 
    f.RowNum
LIMIT 50;
