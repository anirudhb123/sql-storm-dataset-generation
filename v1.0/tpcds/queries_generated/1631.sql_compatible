
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_discount_amt) AS avg_discount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
JoinData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(ws.total_sales, 0) AS total_sales,
        COALESCE(ws.avg_discount, 0) AS avg_discount
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN WebSalesData ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
RankedData AS (
    SELECT 
        j.*,
        RANK() OVER (ORDER BY j.total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY j.total_returns DESC) AS return_rank
    FROM JoinData j
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rv.total_sales,
    rv.total_return_amt,
    rv.sales_rank,
    rv.return_rank,
    CASE 
        WHEN rv.avg_discount > 0 AND rv.total_sales = 0 THEN 'High Return Risk'
        WHEN rv.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Normal'
    END AS customer_status
FROM RankedData rv
JOIN customer c ON rv.c_customer_sk = c.c_customer_sk
WHERE rv.total_sales > 1000
AND rv.total_return_amt IS NOT NULL
ORDER BY rv.sales_rank, rv.return_rank;
