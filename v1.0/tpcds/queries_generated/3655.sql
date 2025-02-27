
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM
        CustomerReturns cr
    JOIN
        customer c ON c.c_customer_id = cr.c_customer_id
    WHERE
        cr.total_return_amount IS NOT NULL
        AND cr.total_returns > 0
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_amount,
    ss.total_sales,
    ss.total_orders,
    (COALESCE(tc.total_return_amount, 0) / NULLIF(ss.total_sales, 0)) * 100 AS return_rate_percentage
FROM
    TopCustomers tc
LEFT JOIN
    SalesSummary ss ON tc.c_customer_id = ss.ws_bill_customer_sk
WHERE
    tc.rank <= 10
ORDER BY
    return_rate_percentage DESC;
