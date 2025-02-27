
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cr.cr_item_sk
)
SELECT 
    rs.web_site_id,
    rs.ws_item_sk,
    rs.ws_sales_price,
    rs.total_quantity,
    COALESCE(fr.total_returned, 0) AS total_returned,
    COALESCE(fr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN fr.total_returned IS NOT NULL THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM RankedSales rs
LEFT JOIN FilteredReturns fr ON rs.ws_item_sk = fr.cr_item_sk
WHERE rs.rank_price <= 5
ORDER BY rs.web_site_id, rs.ws_sales_price DESC;
