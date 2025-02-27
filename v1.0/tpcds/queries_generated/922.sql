
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        ss_store_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, ss_store_sk
),
StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales_value,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
RankedReturns AS (
    SELECT 
        cr.sr_store_sk,
        cr.total_returned,
        cr.total_return_value,
        ss.total_sales_value,
        ss.total_transactions,
        RANK() OVER (PARTITION BY cr.sr_store_sk ORDER BY cr.total_return_value DESC) AS return_rank
    FROM 
        CustomerReturns cr
    JOIN 
        StoreSales ss ON cr.ss_store_sk = ss.ss_store_sk
)
SELECT 
    sr.sr_store_sk,
    COALESCE(rr.total_returned, 0) AS total_returned,
    COALESCE(rr.total_return_value, 0) AS total_return_value,
    COALESCE(ss.total_sales_value, 0) AS total_sales_value,
    COALESCE(ss.total_transactions, 0) AS total_transactions,
    CASE 
        WHEN ss.total_sales_value = 0 THEN NULL
        ELSE ROUND((COALESCE(rr.total_return_value, 0) / ss.total_sales_value) * 100, 2)
    END AS return_rate_percentage
FROM
    StoreSales ss
LEFT OUTER JOIN 
    RankedReturns rr ON ss.ss_store_sk = rr.sr_store_sk AND rr.return_rank = 1
WHERE 
    (ss.total_sales_value > 1000 OR rr.total_returned > 0)
ORDER BY 
    return_rate_percentage DESC NULLS LAST;
