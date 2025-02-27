
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_item_sk,
        sr.return_quantity,
        sr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.return_item_sk ORDER BY sr.returned_date_sk DESC) AS rank
    FROM store_returns sr 
    WHERE sr.return_quantity > 0
),
HighValueReturns AS (
    SELECT 
        rr.return_item_sk,
        SUM(rr.return_amt) AS total_return_amt
    FROM RankedReturns rr
    WHERE rr.rank = 1
    GROUP BY rr.return_item_sk
    HAVING SUM(rr.return_amt) > (SELECT AVG(return_amt) FROM RankedReturns WHERE return_quantity > 0) 
),
HighValueSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_sales_amt,
        COUNT(*) AS sales_count
    FROM web_sales ws
    WHERE ws.ws_net_paid > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_net_paid IS NOT NULL)
    GROUP BY ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(hv.return_quantity, 0) AS total_return_qty,
    COALESCE(hv.total_return_amt, 0) AS total_return_amt,
    COALESCE(hv_sales.total_sales_amt, 0) AS total_sales_amt,
    hv_sales.sales_count AS sales_count,
    CASE 
        WHEN COALESCE(hv.total_return_qty, 0) > 0 THEN 'High Return' 
        ELSE 'Normal' 
    END AS return_status,
    CASE 
        WHEN hv_sales.total_sales_amt IS NULL THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM item i 
LEFT JOIN HighValueReturns hv ON i.i_item_sk = hv.return_item_sk 
LEFT JOIN HighValueSales hv_sales ON i.i_item_sk = hv_sales.ws_item_sk
ORDER BY i.i_item_id;
