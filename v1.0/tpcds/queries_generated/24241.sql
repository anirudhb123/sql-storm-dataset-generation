
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price
    FROM RankedSales rs
    WHERE rs.rn = 1
),
ReturnMetrics AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amt) AS total_returned_amt
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
SalesComparison AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_sales_price,
        COALESCE(rm.total_returned, 0) AS total_returned,
        COALESCE(rm.total_returned_amt, 0) AS total_returned_amt,
        CASE 
            WHEN ts.ws_sales_price - COALESCE(rm.total_returned_amt, 0) > 0 
            THEN 'Profitable' 
            ELSE 'Not Profitable' 
        END AS profitability
    FROM TopSales ts
    LEFT JOIN ReturnMetrics rm ON ts.ws_item_sk = rm.cr_item_sk
)
SELECT 
    sc.ws_item_sk,
    sc.ws_sales_price,
    sc.total_returned,
    sc.total_returned_amt,
    sc.profitability
FROM SalesComparison sc
WHERE sc.total_returned > (SELECT AVG(total_returned) FROM ReturnMetrics)
  AND sc.profitability = 'Profitable'
ORDER BY sc.ws_sales_price DESC
FETCH FIRST 10 ROWS ONLY;
