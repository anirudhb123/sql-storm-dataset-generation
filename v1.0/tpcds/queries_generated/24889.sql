
WITH CustomerReturns AS (
    SELECT 
        COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
        COUNT(DISTINCT sr.returned_date_sk) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        AVG(sr.return_quantity) AS avg_return_quantity,
        STRING_AGG(DISTINCT sr_reason_sk::text, ', ') FILTER (WHERE sr_reason_sk IS NOT NULL) AS return_reasons,
        MAX(sr.returned_date_sk) AS last_return_date
    FROM store_returns sr
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY customer_id
),
WebReturns AS (
    SELECT 
        COALESCE(wr.returning_customer_sk, 0) AS customer_sk,
        SUM(wr.return_amt) AS total_web_return_amt,
        COUNT(wr.return_quantity) AS total_web_returned_items,
        AVG(wr.return_tax) AS avg_web_return_tax
    FROM web_returns wr
    GROUP BY customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_store_returns,
    COALESCE(cr.total_return_amt, 0) AS total_store_return_value,
    COALESCE(cr.avg_return_quantity, 0) AS avg_store_return_qty,
    COALESCE(wr.total_web_return_amt, 0) AS total_web_return_value,
    COALESCE(wr.total_web_returned_items, 0) AS total_web_returned_items,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) = 0 AND COALESCE(wr.total_web_return_amt, 0) = 0 THEN 'No Returns'
        WHEN COALESCE(cr.total_return_amt, 0) > COALESCE(wr.total_web_return_amt, 0) THEN 'Higher Store Returns'
        ELSE 'Higher Web Returns'
    END AS return_type
FROM customer c
LEFT JOIN CustomerReturns cr ON c.c_customer_id = cr.customer_id
LEFT JOIN WebReturns wr ON c.c_customer_sk = wr.customer_sk
WHERE (c.c_preferred_cust_flag = 'Y' OR c.c_birth_year IS NULL)
ORDER BY c.c_last_name ASC, c.c_first_name ASC;
