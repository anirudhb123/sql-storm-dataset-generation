
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        coalesce(cr.total_returned_quantity, 0) AS total_returned_quantity,
        coalesce(cr.total_returned_amount, 0) AS total_returned_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    ORDER BY total_returned_amount DESC
    LIMIT 10
),
DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE dd.d_year = 2023
    GROUP BY dd.d_date
),
SalesAndReturns AS (
    SELECT 
        d.d_date,
        d.total_sales,
        d.total_orders,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (d.total_sales - COALESCE(r.total_returned_amount, 0)) AS net_sales
    FROM DailySales d
    LEFT JOIN (
        SELECT 
            dd.d_date,
            SUM(sr.sr_return_quantity) AS total_returned_quantity,
            SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
        FROM date_dim dd
        LEFT JOIN store_returns sr ON dd.d_date_sk = sr.sr_returned_date_sk
        WHERE dd.d_year = 2023
        GROUP BY dd.d_date
    ) r ON d.d_date = r.d_date
)
SELECT 
    s.d_date,
    s.total_sales,
    s.total_orders,
    s.total_returned_quantity,
    s.total_returned_amount,
    s.net_sales,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status
FROM SalesAndReturns s
JOIN TopCustomers tc ON tc.c_customer_sk = (
    SELECT c.c_customer_sk 
    FROM customer c
    WHERE c.c_birth_month = EXTRACT(MONTH FROM s.d_date)
    ORDER BY c.c_birth_year DESC
    LIMIT 1
)
WHERE s.net_sales > 0
ORDER BY s.d_date DESC, s.net_sales DESC;
