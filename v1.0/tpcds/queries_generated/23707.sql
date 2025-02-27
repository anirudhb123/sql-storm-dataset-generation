
WITH RECURSIVE CustomerReturns AS (
    SELECT
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    WHERE sr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk, sr_customer_sk
),
TopReturningCustomers AS (
    SELECT
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cr.total_returned), 0) AS total_items_returned
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE cr.rn <= 5
    GROUP BY cr.sr_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    w.w_warehouse_name,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_value,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS unique_refunding_customers
FROM web_returns wr
JOIN web_site w ON wr.wr_web_page_sk = w.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM TopReturningCustomers tc
    WHERE tc.sr_customer_sk = wr.wr_returning_customer_sk
)
AND wr.wr_returned_date_sk IN (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year BETWEEN 2021 AND 2023
)
GROUP BY w.w_warehouse_name
HAVING SUM(wr.wr_return_amt_inc_tax) > (
    SELECT AVG(total_items_returned)
    FROM TopReturningCustomers
)
ORDER BY total_return_value DESC
LIMIT 10;
