
WITH RankedSales AS (
    SELECT 
        ws.item_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.date_sk
    WHERE 
        dd.year = 2023 
        AND ws.net_paid_inc_tax IS NOT NULL
    GROUP BY 
        ws.item_sk
), 
TotalReturns AS (
    SELECT 
        cr.item_sk, 
        SUM(cr.return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.item_sk
), 
SalesStatistics AS (
    SELECT 
        rs.item_sk,
        rs.total_sales,
        COALESCE(tr.total_return_amount, 0) AS total_returns,
        (rs.total_sales - COALESCE(tr.total_return_amount, 0)) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.item_sk = tr.item_sk
)
SELECT 
    item.item_id,
    s.net_sales,
    CASE 
        WHEN s.net_sales > 0 THEN 'Positive'
        WHEN s.net_sales = 0 THEN 'Neutral'
        ELSE 'Negative'
    END AS sales_status,
    CASE 
        WHEN s.net_sales IS NULL THEN 'No sales data'
        ELSE 'Sales data available'
    END AS data_availability
FROM 
    SalesStatistics s
JOIN 
    item ON s.item_sk = item.item_sk
WHERE 
    s.net_sales >= (SELECT AVG(net_sales) FROM SalesStatistics)
    OR s.net_sales IS NULL
ORDER BY 
    inventory_quantity DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
