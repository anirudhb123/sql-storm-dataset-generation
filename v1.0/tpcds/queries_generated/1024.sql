
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        RANK() OVER (PARTITION BY sr.item_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
), 
ActiveItems AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        i.current_price,
        i.wholesale_cost
    FROM 
        item i
    WHERE 
        i.rec_start_date <= CURRENT_DATE 
        AND (i.rec_end_date IS NULL OR i.rec_end_date > CURRENT_DATE)
), 
AggregatedReturns AS (
    SELECT 
        r.item_sk,
        SUM(r.return_quantity) AS total_returned_quantity,
        SUM(r.return_amt) AS total_returned_amount
    FROM 
        RankedReturns r
    WHERE 
        r.rn = 1
    GROUP BY 
        r.item_sk
)
SELECT 
    ai.item_sk,
    ai.item_desc,
    ai.current_price,
    ai.wholesale_cost,
    COALESCE(ar.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(ar.total_returned_amount, 0) AS total_returned_amount,
    (ai.current_price - ai.wholesale_cost) AS profit_margin,
    CASE 
        WHEN COALESCE(ar.total_returned_amount, 0) > 0 
        THEN 'Returns Processed'
        ELSE 'No Returns'
    END AS return_status
FROM 
    ActiveItems ai
LEFT JOIN 
    AggregatedReturns ar ON ai.item_sk = ar.item_sk
WHERE 
    (ai.current_price - ai.wholesale_cost) > 0 
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.store_sk = (SELECT ss.store_sk FROM store_sales ss WHERE ss.item_sk = ai.item_sk LIMIT 1)
        AND s.city IS NOT NULL
    )
ORDER BY 
    profit_margin DESC, 
    ai.item_desc ASC;
