
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
AggregatedSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        COALESCE(ws.total_quantity, 0) AS total_quantity,
        COALESCE(ws.total_sales, 0) AS total_sales,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (COALESCE(ws.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales,
        RANK() OVER (ORDER BY (COALESCE(ws.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) DESC) AS sales_rank
    FROM 
        item
    LEFT JOIN 
        RecursiveSales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON item.i_item_sk = cr.cr_item_sk
)
SELECT 
    a.i_item_sk,
    a.i_item_desc,
    a.total_quantity,
    a.total_sales,
    a.total_return_quantity,
    a.total_return_amount,
    a.net_sales
FROM 
    AggregatedSales a
WHERE 
    a.total_quantity > 0
    AND a.net_sales > 1000
ORDER BY 
    a.sales_rank
LIMIT 10

UNION ALL

SELECT 
    g.i_item_sk,
    g.i_item_desc,
    g.total_quantity,
    g.total_sales,
    g.total_return_quantity,
    g.total_return_amount,
    g.net_sales
FROM 
    AggregatedSales g
WHERE 
    g.net_sales IS NULL
ORDER BY 
    g.i_item_sk;
