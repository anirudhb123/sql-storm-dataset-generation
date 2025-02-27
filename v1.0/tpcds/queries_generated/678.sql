
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
),
RankedReturns AS (
    SELECT 
        cr.returning_customer,
        cr.total_return_amount,
        cr.total_returns,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM CustomerReturns cr
),
RankedSales AS (
    SELECT 
        ss.ws_bill_customer_sk,
        ss.total_sales_amount,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales_amount DESC) AS sales_rank
    FROM SalesSummary ss
)
SELECT 
    r.customers_customer_sk,
    COALESCE(sr.total_sales_amount, 0) AS total_sales,
    COALESCE(cr.total_return_amount, 0) AS total_returns,
    sr.sales_rank,
    cr.return_rank
FROM RankedSales sr
FULL OUTER JOIN RankedReturns cr ON sr.ws_bill_customer_sk = cr.returning_customer
WHERE (sr.total_orders > 5 OR cr.total_returns > 2)
AND (sr.total_sales_amount IS NOT NULL OR cr.total_return_amount IS NOT NULL)
ORDER BY COALESCE(sr.total_sales_amount, 0) DESC, COALESCE(cr.total_return_amount, 0) DESC
LIMIT 100;
