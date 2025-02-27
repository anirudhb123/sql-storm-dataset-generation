
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
TotalReturns AS (
    SELECT 
        COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        cr_item_sk
    FROM 
        catalog_returns cr
    FULL OUTER JOIN web_returns wr ON cr.cr_item_sk = wr.wr_item_sk
    GROUP BY 
        COALESCE(cr.cr_item_sk, wr.wr_item_sk)
),
ItemDetails AS (
    SELECT 
        it.i_item_sk,
        it.i_product_name,
        it.i_current_price,
        COALESCE(ts.total_catalog_returns, 0) AS catalog_returns,
        COALESCE(ts.total_web_returns, 0) AS web_returns,
        CASE 
            WHEN COALESCE(ts.total_catalog_returns, 0) > 0 THEN 'Returned'
            WHEN COALESCE(ts.total_web_returns, 0) > 0 THEN 'Web Returned'
            ELSE 'No Returns'
        END AS ReturnStatus
    FROM 
        item it
    LEFT JOIN TotalReturns ts ON it.i_item_sk = ts.cr_item_sk
)
SELECT 
    id.i_product_name,
    id.i_current_price,
    id.catalog_returns,
    id.web_returns,
    id.ReturnStatus,
    rs.SalesRank
FROM 
    ItemDetails id
LEFT JOIN RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.SalesRank = 1
WHERE 
    id.i_current_price = (SELECT MAX(i_current_price) 
                          FROM ItemDetails 
                          WHERE ReturnStatus = 'No Returns')
ORDER BY 
    id.i_product_name ASC NULLS LAST
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    'Total Returns' AS Priority,
    COALESCE(SUM(id.catalog_returns), 0) AS Price,
    NULL,
    NULL,
    NULL,
    NULL
FROM 
    ItemDetails id
WHERE 
    id.ReturnStatus = 'Returned';
