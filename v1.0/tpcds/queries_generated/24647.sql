
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
), 
FailedReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity < 0
    GROUP BY 
        cr_item_sk
),
SalesSummary AS (
    SELECT 
        a.i_item_id,
        COALESCE(b.total_sales, 0) AS total_web_sales,
        COALESCE(c.total_returns, 0) AS total_failed_returns
    FROM 
        item a
    LEFT JOIN 
        (SELECT 
            ws_item_sk, 
            SUM(ws_ext_sales_price) AS total_sales 
         FROM 
            web_sales 
         WHERE 
            ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales) 
         GROUP BY 
            ws_item_sk) b ON a.i_item_sk = b.ws_item_sk
    LEFT JOIN 
        FailedReturns c ON a.i_item_sk = c.cr_item_sk
)
SELECT 
    s.i_item_id,
    s.total_web_sales,
    s.total_failed_returns,
    CASE 
        WHEN s.total_web_sales > 1000 THEN 'High Sales'
        WHEN s.total_web_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales' 
    END AS sales_category,
    (SELECT 
        COUNT(DISTINCT ws_order_number) 
     FROM 
        web_sales 
     WHERE 
        ws_item_sk = s.i_item_sk) AS distinct_order_count
FROM 
    SalesSummary s
WHERE 
    (s.total_failed_returns IS NULL OR s.total_failed_returns > 0) 
    AND s.total_web_sales < (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY 
    s.total_web_sales DESC
FETCH FIRST 10 ROWS ONLY;
