
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity IS NOT NULL
    GROUP BY 
        cr_item_sk
),
SalesWithReturns AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(rs.total_sales, 0) AS sales_amount,
        COALESCE(fr.total_returns, 0) AS returns_amount,
        (COALESCE(rs.total_sales, 0) - COALESCE(fr.total_returns, 0)) AS net_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
    LEFT JOIN 
        FilteredReturns fr ON ws.ws_item_sk = fr.cr_item_sk
)
SELECT 
    DISTINCT i.i_item_id,
    i.i_item_desc,
    CASE 
        WHEN net_sales < 0 THEN 'Loss Leader'
        WHEN net_sales BETWEEN 0 AND 1000 THEN 'Low Performer'
        WHEN net_sales BETWEEN 1000 AND 5000 THEN 'Average Performer'
        ELSE 'High Performer'
    END AS performance_category,
    CASE 
        WHEN i.i_current_price IS NULL THEN 'Price Unknown'
        ELSE CONCAT('Price: ', CAST(i.i_current_price AS VARCHAR), ' USD')
    END AS item_price_info
FROM 
    SalesWithReturns swr
JOIN 
    item i ON swr.ws_item_sk = i.i_item_sk
WHERE 
    swr.net_sales IS NOT NULL 
    AND (swr.net_sales BETWEEN -1000 AND 10000 OR swr.net_sales IS NULL)
ORDER BY 
    swr.net_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

```
