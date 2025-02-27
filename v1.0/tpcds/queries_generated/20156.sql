
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
TopReturns AS (
    SELECT 
        r.return_count,
        r.total_return_amt,
        i.i_item_id,
        i.i_item_desc,
        d.d_date,
        w.w_warehouse_name,
        CASE 
            WHEN r.return_count = 1 THEN 'Single Return'
            WHEN r.return_count > 1 AND r.return_count <= 5 THEN 'Multiple Returns'
            ELSE 'Excessive Returns'
        END AS return_category
    FROM RankedReturns r
    JOIN item i ON r.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN warehouse w ON i.i_item_sk % (SELECT COUNT(*) FROM warehouse) = w.w_warehouse_sk
    WHERE rnk = 1
)
SELECT 
    TRIM(CONCAT(i.i_item_desc, ' - ', TRIM(w.w_warehouse_name))) AS item_warehouse,
    COALESCE(t.return_count, 0) AS return_count,
    ROUND(COALESCE(t.total_return_amt, 0), 2) AS total_return_amount,
    REPLACE(return_category, 'Returns', 'Issues') AS issue_category
FROM TopReturns t
FULL OUTER JOIN item i ON t.i_item_sk = i.i_item_sk
WHERE 
    COALESCE(t.total_return_amt, 0) > 100 OR 
    (t.return_count IS NULL AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = i.i_item_sk AND ss.ss_sales_price > 50
    ))
ORDER BY total_return_amount DESC, return_category DESC;

