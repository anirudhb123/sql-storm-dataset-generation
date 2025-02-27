
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned,
        cr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned DESC) AS rn
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE cr.total_returned > 0
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
ReturnStats AS (
    SELECT 
        tc.c_customer_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        tc.total_returned,
        tc.total_return_amount,
        (tc.total_return_amount / NULLIF(sd.total_sales, 0)) * 100 AS return_percentage
    FROM TopCustomers tc
    LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.total_sales,
    r.total_returned,
    (SELECT return_count FROM CustomerReturns cr WHERE cr.cr_returning_customer_sk = r.c_customer_sk) AS return_count,
    r.return_percentage,
    CASE 
        WHEN r.return_percentage > 50 THEN 'High Risk'
        WHEN r.return_percentage BETWEEN 20 AND 50 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM ReturnStats r
WHERE r.total_returned > 5
ORDER BY r.return_percentage DESC;
