
WITH RECURSIVE CustomerReturns AS (
    SELECT DISTINCT 
        sr_returning_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_returned_date_sk,
        NULL AS ParentReturn
    FROM store_returns
    WHERE sr_return_quantity >= 1

    UNION ALL

    SELECT
        cr.returning_customer_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_tax,
        cr.returned_date_sk,
        cr.returning_customer_sk AS ParentReturn
    FROM catalog_returns cr
    JOIN CustomerReturns crp ON crp.sr_returning_customer_sk = cr.refunded_customer_sk
    WHERE cr.return_quantity IS NOT NULL AND cr.return_quantity > crp.sr_return_quantity
)

SELECT
    ca.city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(sr.return_amt) AS total_return_amount,
    AVG(sr.return_quantity) AS avg_return_quantity,
    CASE 
        WHEN AVG(sr.return_quantity) IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status,
    DENSE_RANK() OVER (ORDER BY SUM(sr.return_amt) DESC) AS return_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt) AS return_amt,
        AVG(sr_return_quantity) AS return_quantity
    FROM CustomerReturns
    GROUP BY sr_returning_customer_sk
) sr ON sr.sr_returning_customer_sk = c.c_customer_sk
WHERE ca.ca_city IS NOT NULL AND ca.ca_state = 'CA'
GROUP BY ca.city
HAVING COUNT(DISTINCT c.c_customer_id) > 10 
   AND total_return_amount >= (SELECT AVG(total_return)
                               FROM (
                                   SELECT SUM(sr.return_amt) AS total_return
                                   FROM store_returns sr
                                   GROUP BY sr.returning_customer_sk
                               ) AS avg_return_subquery)
ORDER BY return_rank, ca.city;
