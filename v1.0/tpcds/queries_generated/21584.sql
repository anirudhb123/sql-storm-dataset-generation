
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        COALESCE(CAST(SUM(sr.return_quantity) AS INTEGER), 0) AS total_returned_quantity,
        COALESCE(SUM(sr.return_amt), 0) AS total_returned_amt,
        COUNT(DISTINCT sr.customer_sk) AS unique_customers_returned
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk IS NOT NULL
    GROUP BY 
        sr.returned_date_sk, sr.return_time_sk, sr.item_sk
),
WebReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.return_time_sk,
        wr.item_sk,
        COALESCE(SUM(wr.return_quantity), 0) AS web_returned_quantity,
        COALESCE(SUM(wr.return_amt), 0) AS web_returned_amt,
        COUNT(DISTINCT wr.returning_customer_sk) AS unique_web_customers_returned
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk IS NOT NULL
    GROUP BY 
        wr.returned_date_sk, wr.return_time_sk, wr.item_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(c.returned_date_sk, w.returned_date_sk) AS return_date_sk,
        COALESCE(c.return_time_sk, w.return_time_sk) AS return_time_sk,
        COALESCE(c.item_sk, w.item_sk) AS item_sk,
        COALESCE(c.total_returned_quantity, 0) + COALESCE(w.web_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(c.total_returned_amt, 0) + COALESCE(w.web_returned_amt, 0) AS total_returned_amt,
        COALESCE(c.unique_customers_returned, 0) + COALESCE(w.unique_web_customers_returned, 0) AS total_unique_customers_returned
    FROM 
        CustomerReturns c
    FULL OUTER JOIN 
        WebReturns w ON c.returned_date_sk = w.returned_date_sk AND c.return_time_sk = w.return_time_sk AND c.item_sk = w.item_sk
)
SELECT 
    cr.return_date_sk,
    cr.return_time_sk,
    cr.item_sk,
    cr.total_returned_quantity,
    cr.total_returned_amt,
    cr.total_unique_customers_returned,
    DENSE_RANK() OVER (PARTITION BY cr.item_sk ORDER BY cr.total_returned_amt DESC) AS rank_based_on_amt,
    CASE 
        WHEN cr.total_returned_quantity = 0 THEN 'No returns'
        WHEN cr.total_returned_quantity > 100 THEN 'High return volume'
        ELSE 'Moderate return volume' 
    END AS return_volume_category
FROM 
    CombinedReturns cr
WHERE 
    cr.total_returned_amt > 0 
    OR cr.total_unique_customers_returned > 0
ORDER BY 
    cr.return_date_sk, cr.return_time_sk, cr.item_sk;
