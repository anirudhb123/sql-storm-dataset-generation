
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(cr.total_returned, 0) / COALESCE(sd.total_sales, 0)) * 100
        END AS return_rate_percentage
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_returning_customer_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_returned,
    cs.total_sales,
    cs.return_rate_percentage,
    CASE 
        WHEN cs.return_rate_percentage IS NULL OR cs.return_rate_percentage < 10 THEN 'Low'
        WHEN cs.return_rate_percentage BETWEEN 10 AND 20 THEN 'Moderate'
        ELSE 'High'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY cs.return_category ORDER BY cs.total_sales DESC) AS rank_within_category
FROM CustomerStats cs
WHERE cs.return_rate_percentage IS NOT NULL
AND cs.return_category IS NOT NULL
ORDER BY cs.return_category, rank_within_category
OFFSET (SELECT COUNT(*) FROM CustomerStats WHERE return_rate_percentage IS NOT NULL AND return_category IS NOT NULL) / 2
ROW FETCH NEXT 10 ROWS ONLY;
