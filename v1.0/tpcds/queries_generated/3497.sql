
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COALESCE(SUM(CASE WHEN rs.rank = 1 THEN ws.ws_sales_price ELSE 0 END), 0) AS latest_sales_price,
        COALESCE(cr.total_returned, 0) AS total_returns
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    s.i_item_id,
    CONCAT('Item ID: ', s.i_item_id, ' | Total Sales: $', ROUND(s.total_sales, 2), ' | Latest Sales Price: $', ROUND(s.latest_sales_price, 2), ' | Total Returns: ', s.total_returns) AS sales_info
FROM 
    SalesSummary s
WHERE 
    s.total_sales > 10000 OR s.latest_sales_price > 100
ORDER BY 
    total_sales DESC
LIMIT 10;
