
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cr.cr_item_sk
),
SalesAndReturns AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales,
        COALESCE(tr.total_returned, 0) AS total_returns,
        COALESCE(SUM(ws.ws_quantity), 0) - COALESCE(tr.total_returned, 0) AS net_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        TotalReturns tr ON i.i_item_sk = tr.cr_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    sar.i_item_id,
    sar.total_sales,
    sar.total_returns,
    sar.net_sales,
    CASE 
        WHEN sar.net_sales > 0 THEN CONCAT('Positive sales: ', sar.net_sales)
        ELSE 'No positive sales'
    END AS sales_status,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS customer_count,
    (SELECT COUNT(DISTINCT ca.ca_city) FROM customer_address ca) AS unique_cities
FROM 
    SalesAndReturns sar
WHERE 
    sar.net_sales >= (
        SELECT AVG(net_sales) FROM SalesAndReturns
    )
ORDER BY 
    sar.net_sales DESC
LIMIT 10; 
