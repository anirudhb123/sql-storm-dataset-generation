
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_item_sk) AS total_web_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_item_sk) AS total_store_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
ReturnStats AS (
    SELECT 
        cr.wr_returning_customer_sk AS customer_sk,
        COALESCE(cr.total_web_returns, 0) AS web_returns,
        COALESCE(sr.total_store_returns, 0) AS store_returns,
        (COALESCE(cr.total_return_amount, 0) + COALESCE(sr.total_return_amount, 0)) AS total_returned
    FROM CustomerReturns cr
    FULL OUTER JOIN StoreReturns sr ON cr.wr_returning_customer_sk = sr.sr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(ws_order_number) AS total_web_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    rs.customer_sk,
    rs.web_returns,
    rs.store_returns,
    rs.total_returned,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(sd.total_web_orders, 0) AS total_web_orders
FROM ReturnStats rs
LEFT JOIN SalesData sd ON rs.customer_sk = sd.customer_sk
WHERE rs.total_returned > 0
ORDER BY rs.total_returned DESC, sd.total_web_sales DESC;
