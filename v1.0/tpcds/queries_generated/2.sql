
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return,
        COUNT(*) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr1.sr_customer_sk,
        cr1.total_return,
        cr1.return_count,
        ROW_NUMBER() OVER (ORDER BY cr1.total_return DESC) AS return_rank
    FROM CustomerReturns cr1
    WHERE cr1.total_return > (SELECT AVG(total_return) FROM CustomerReturns)
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws_item_sk
),
ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned,
        COUNT(*) AS return_count
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY wr_item_sk
),
OverallReturns AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(is.total_sales, 0) AS total_sales,
        COALESCE(ir.total_returned, 0) AS total_returned,
        (COALESCE(is.total_sales, 0) - COALESCE(ir.total_returned, 0)) AS net_sales
    FROM ItemSales is
    FULL OUTER JOIN ItemReturns ir ON is.ws_item_sk = ir.wr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_return, 0) AS total_customer_return,
    COALESCE(cr.return_count, 0) AS customer_return_count,
    o.ws_item_sk,
    o.total_sales,
    o.total_returned,
    o.net_sales
FROM HighReturnCustomers cr
JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
JOIN OverallReturns o ON o.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE cr.return_rank <= 10
ORDER BY total_customer_return DESC, net_sales ASC;
