
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_store_sk
), 
TotalReturns AS (
    SELECT 
        item.i_item_id,
        COALESCE(rr.total_returned, 0) AS total_returned,
        CASE 
            WHEN rr.rank IS NULL THEN 'No Returns'
            ELSE 'Returned'
        END AS return_status
    FROM 
        item 
    LEFT JOIN 
        RankedReturns rr ON item.i_item_sk = rr.sr_item_sk AND rr.rank = 1
), 
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY d.d_month_seq ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq, ws.ws_item_sk
)
SELECT 
    t.item_id,
    t.total_returned,
    COALESCE(ms.total_sales, 0) AS total_sales,
    t.return_status,
    CASE 
        WHEN t.total_returned > 100 AND ms.total_sales < 1000 THEN 'High Returns, Low Sales'
        WHEN t.total_returned > 100 THEN 'High Returns'
        WHEN ms.total_sales < 1000 THEN 'Low Sales'
        ELSE 'Normal'
    END AS performance_category
FROM 
    TotalReturns t
LEFT JOIN 
    MonthlySales ms ON ms.ws_item_sk = t.i_item_id
WHERE 
    t.return_status = 'Returned'
    OR (t.return_status = 'No Returns' AND ms.total_sales IS NOT NULL)
ORDER BY 
    t.total_returned DESC, 
    ms.total_sales ASC 
LIMIT 50 
OFFSET (SELECT COUNT(*) FROM item) / 2; 
