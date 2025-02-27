
WITH ItemSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY item.i_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_sales
    FROM 
        item item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_desc
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
SalesAndReturns AS (
    SELECT 
        is.i_item_sk,
        is.i_item_desc,
        COALESCE(is.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(is.total_sales, 0) AS total_sales,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        ItemSales is
    FULL OUTER JOIN 
        CustomerReturns cr ON is.i_item_sk = cr.cr_item_sk
)
SELECT 
    sar.i_item_sk,
    sar.i_item_desc,
    sar.total_quantity_sold,
    sar.total_sales,
    sar.total_return_quantity,
    sar.total_return_amount,
    (sar.total_sales - sar.total_return_amount) AS net_sales,
    CASE 
        WHEN sar.total_quantity_sold = 0 THEN NULL 
        ELSE (sar.total_return_quantity * 100.0 / sar.total_quantity_sold) 
    END AS return_rate
FROM 
    SalesAndReturns sar
WHERE 
    sar.total_sales > 1000
ORDER BY 
    net_sales DESC
LIMIT 10;
