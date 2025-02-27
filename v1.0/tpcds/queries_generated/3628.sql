
WITH RankedSales AS (
    SELECT 
        ws_items.item_id,
        ws_items.web_sales_date,
        ws_items.sales_price,
        RANK() OVER (PARTITION BY ws_items.item_id ORDER BY ws_items.sales_price DESC) AS price_rank
    FROM 
        web_sales ws_items
    JOIN 
        item it ON ws_items.ws_item_sk = it.i_item_sk
    WHERE 
        ws_items.ws_sold_date_sk BETWEEN 202200000 AND 202209999
),
TotalReturns AS (
    SELECT 
        item_id,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_returned,
        SUM(COALESCE(wr_return_amt, 0)) AS total_amount_returned
    FROM 
        web_returns wr
    GROUP BY 
        item_id
),
SalesAndReturns AS (
    SELECT 
        s.item_id,
        COALESCE(t.total_returned, 0) AS total_returned,
        SUM(s.sales_price) AS total_sales,
        SUM(s.sales_price) - COALESCE(t.total_amount_returned, 0) AS net_sales
    FROM 
        RankedSales s
    LEFT JOIN 
        TotalReturns t ON s.item_id = t.item_id
    GROUP BY 
        s.item_id, t.total_returned
)
SELECT 
    sr.item_id,
    sr.total_sales,
    sr.total_returned,
    sr.net_sales,
    CASE 
        WHEN sr.total_sales > 0 THEN (sr.net_sales / sr.total_sales) * 100
        ELSE 0
    END AS sales_return_rate
FROM 
    SalesAndReturns sr
WHERE 
    sr.total_sales > 1000
ORDER BY 
    sales_return_rate DESC
LIMIT 10;
