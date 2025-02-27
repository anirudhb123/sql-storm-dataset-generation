
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        CASE 
            WHEN SUM(sr_return_quantity) IS NULL THEN 'No Returns'
            WHEN SUM(sr_return_quantity) > 10 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS return_category
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
RankedReturns AS (
    SELECT 
        c.customer_sk,
        c.customer_id,
        cr.total_returns,
        cr.return_count,
        cr.return_category,
        RANK() OVER (PARTITION BY cr.return_category ORDER BY cr.total_returns DESC) AS rank_within_category
    FROM CustomerReturns cr
    JOIN customer c ON cr.c_customer_id = c.c_customer_id
),
HighReturnCustomers AS (
    SELECT customer_sk, customer_id, total_returns, return_count, return_category
    FROM RankedReturns
    WHERE rank_within_category <= 5
)
SELECT 
    c.c_customer_sk,
    c.c_customer_id,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.return_count, 0) AS return_count,
    cr.return_category,
    d.d_date AS return_date,
    i.i_item_desc,
    ws.ws_sales_price,
    CASE 
        WHEN cr.total_returns IS NULL THEN 'Unknown'
        WHEN cr.total_returns > 0 AND cr.return_count > 5 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM HighReturnCustomers cr
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(sr_returned_date_sk) 
    FROM store_returns sr 
    WHERE sr.sr_customer_sk = cr.customer_sk 
    GROUP BY sr.sr_customer_sk
)
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = cr.customer_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_current_price > (
    SELECT AVG(i_current_price) 
    FROM item 
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
)
  AND cr.return_category <> 'No Returns'
ORDER BY risk_level DESC, cr.total_returns DESC;
