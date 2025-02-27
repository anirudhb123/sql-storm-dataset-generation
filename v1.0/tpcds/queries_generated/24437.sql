
WITH RankedReturns AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sold,
        SUM(COALESCE(sr.return_quantity, 0)) AS total_returned,
        SUM(COALESCE(sr.return_amt, 0)) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(COALESCE(sr.return_amt, 0)) DESC) AS rank
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns sr ON ws.ws_order_number = sr.wr_order_number AND ws.ws_item_sk = sr.wr_item_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
TopReturns AS (
    SELECT 
        rr.ws_item_sk,
        rr.total_sold,
        rr.total_returned,
        rr.total_return_amt,
        CASE 
            WHEN rr.total_returned IS NULL THEN 'No Returns'
            ELSE 'Returned'
        END AS return_status
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank = 1
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS refund_total
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk 
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT wr.wr_order_number) > 5 OR SUM(COALESCE(wr.wr_return_amt, 0)) > 100
)
SELECT 
    tc.ws_item_sk,
    tc.total_sold,
    tc.total_returned,
    tc.total_return_amt,
    cr.return_count,
    cr.refund_total,
    CONCAT('Customer ID:', cr.c_customer_id, ' | Returns Status: ', tc.return_status) AS detailed_info
FROM 
    TopReturns tc
LEFT JOIN 
    CustomerReturns cr ON tc.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_order_number IN (SELECT wr_order_number FROM web_returns WHERE wr_item_sk = tc.ws_item_sk))
WHERE 
    (tc.total_return_amt < 500 AND tc.total_returned IS NOT NULL)
    OR 
    (tc.total_returned IS NULL AND cr.return_count IS NOT NULL)
ORDER BY 
    tc.total_return_amt DESC, cr.return_count DESC;
