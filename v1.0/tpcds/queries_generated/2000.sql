
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
StoreWebSales AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerStatistics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ss.total_spent, 0) AS total_spent,
        COALESCE(ss.total_orders, 0) AS total_orders,
        CASE
            WHEN COALESCE(ss.total_spent, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(ss.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        customer AS c
    LEFT JOIN
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN
        StoreWebSales AS ss ON c.c_customer_sk = ss.customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_spent,
    cs.total_orders,
    cs.customer_value,
    d.d_date AS return_date
FROM
    CustomerStatistics cs
JOIN
    date_dim d ON d.d_date_sk = (
        SELECT
            MAX(d2.d_date_sk)
        FROM
            store_returns sr
        JOIN
            date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
        WHERE
            sr.sr_customer_sk = cs.c_customer_sk
    )
WHERE
    d.d_year = 2023
ORDER BY
    total_return_amount DESC
LIMIT 100;
