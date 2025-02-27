
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_reason_sk, 
        sr_return_quantity, 
        sr_return_amt,
        1 AS level
    FROM store_returns
    WHERE sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr.returned_date_sk, 
        sr.item_sk, 
        sr.customer_sk, 
        sr.reason_sk, 
        sr.return_quantity, 
        sr.return_amt,
        level + 1
    FROM store_returns sr
    JOIN CustomerReturns cr ON sr.customer_sk = cr.sr_customer_sk AND sr.returned_date_sk = cr.sr_returned_date_sk
    WHERE level < 5
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
ReturnsSummary AS (
    SELECT 
        cr.sr_item_sk,
        SUM(cr.sr_return_quantity) AS total_returned_quantity,
        SUM(cr.sr_return_amt) AS total_returned_amount,
        COUNT(cr.sr_reason_sk) AS total_reasons
    FROM CustomerReturns cr 
    GROUP BY cr.sr_item_sk
),
Combined AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales_quantity,
        sd.total_sales_amount,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(rs.total_reasons, 0) AS total_reasons,
        (sd.total_sales_quantity - COALESCE(rs.total_returned_quantity, 0)) AS net_sales_quantity,
        (sd.total_sales_amount - COALESCE(rs.total_returned_amount, 0)) AS net_sales_amount
    FROM SalesData sd
    LEFT JOIN ReturnsSummary rs ON sd.ws_item_sk = rs.sr_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cb.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(cb.total_returned_quantity, 0) AS total_returned_quantity,
    cb.net_sales_quantity,
    cb.net_sales_amount
FROM customer c
LEFT JOIN Combined cb ON c.c_customer_sk = cb.ws_item_sk
WHERE cb.net_sales_quantity > 0 OR cb.net_sales_amount > 0
ORDER BY net_sales_amount DESC
LIMIT 100;
