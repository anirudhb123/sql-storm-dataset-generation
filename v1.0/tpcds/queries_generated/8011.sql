
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        s.customer_sk,
        COALESCE(c.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        COALESCE(w.total_returned_quantity, 0) AS web_total_returned_quantity,
        COALESCE(w.total_returns, 0) AS web_total_returns,
        COALESCE(w.total_return_amount, 0) AS web_total_return_amount,
        sd.total_sales,
        sd.total_net_profit,
        sd.order_count
    FROM SalesData sd
    LEFT JOIN CustomerReturns c ON sd.customer_sk = c.cr_returning_customer_sk
    LEFT JOIN WebReturns w ON sd.customer_sk = w.wr_returning_customer_sk
)
SELECT 
    c.customer_sk,
    c.total_sales,
    c.total_net_profit,
    c.total_returns,
    c.total_returned_quantity,
    c.total_return_amount,
    c.web_total_returns,
    c.web_total_returned_quantity,
    c.web_total_return_amount
FROM CombinedData c
WHERE c.total_sales > 1000
ORDER BY c.total_returned_quantity DESC, c.total_sales DESC
LIMIT 100;
