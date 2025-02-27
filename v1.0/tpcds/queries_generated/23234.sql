
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        sr_ticket_number, 
        SUM(sr_return_quantity) AS total_returned, 
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_ticket_number
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk, 
        rr.sr_ticket_number, 
        rr.total_returned, 
        rr.total_returned_amt,
        cb.c_customer_id,
        dp.d_day_name,
        sm.sm_type
    FROM 
        RankedReturns rr
    JOIN 
        customer cb ON rr.sr_ticket_number = cb.c_customer_sk
    JOIN 
        date_dim dp ON dp.d_date_sk = rr.sr_returned_date_sk
    JOIN 
        ship_mode sm ON sm.sm_ship_mode_sk = (SELECT MIN(sm_ship_mode_sk) FROM ship_mode)
    WHERE 
        rr.rnk = 1 AND rr.total_returned > 10
),
FinalMetrics AS (
    SELECT 
        tr.sr_item_sk,
        COUNT(DISTINCT tr.c_customer_id) AS unique_customers,
        AVG(tr.total_returned_amt) AS avg_returned_amount,
        SUM(tr.total_returned) AS total_quantity_returned,
        MAX(tr.total_returned_amt) AS max_returned_amt,
        MIN(tr.total_returned_amt) AS min_returned_amt
    FROM 
        TopReturns tr
    GROUP BY 
        tr.sr_item_sk
)
SELECT 
    f.sr_item_sk,
    f.unique_customers,
    ROUND(f.avg_returned_amount, 2) AS rounded_avg_returned,
    CASE 
        WHEN f.total_quantity_returned IS NULL THEN 'No returns'
        ELSE 'Returns exist'
    END AS return_status,
    COALESCE(f.max_returned_amt, 0) - COALESCE(f.min_returned_amt, 0) AS return_amt_range
FROM 
    FinalMetrics f
ORDER BY 
    f.unique_customers DESC, f.return_amt_range DESC
LIMIT 10;
