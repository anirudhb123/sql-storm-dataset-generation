
WITH RankedReturns AS (
    SELECT 
        cr_item_sk,
        cr_return_quantity,
        cr_return_amt,
        RANK() OVER (PARTITION BY cr_item_sk ORDER BY cr_return_amt DESC) AS return_rank
    FROM catalog_returns
    WHERE cr_return_timestamp IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_id,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_returning_customer_sk
),
JoinReturns AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cr.return_rank IS NULL THEN 'No Return'
            ELSE 'Returned'
        END AS return_status,
        cr.total_returned,
        cr.total_returned_amt,
        COALESCE(cr.return_count, 0) AS web_return_count
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.customer_id
    LEFT JOIN RankedReturns r ON r.cr_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
)

SELECT 
    j.c_customer_id,
    j.return_status,
    j.total_returned,
    j.total_returned_amt,
    j.web_return_count,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM JoinReturns j
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = j.c_customer_id
GROUP BY 
    j.c_customer_id,
    j.return_status,
    j.total_returned,
    j.total_returned_amt,
    j.web_return_count
HAVING 
    (j.total_returned > 10 AND j.return_status = 'Returned')
    OR (j.return_status = 'No Return' AND total_spent < 100)
ORDER BY total_spent DESC NULLS LAST;

```
