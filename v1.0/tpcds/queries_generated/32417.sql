
WITH RECURSIVE CustomerReturns AS (
    SELECT
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        MAX(sr_return_amt_inc_tax) AS max_return_amt
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned,
        cr.return_count,
        cr.max_return_amt,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned DESC) AS rn
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    COALESCE(STUFF((
        SELECT ', ' + ca.ca_street_number + ' ' + ca.ca_street_name + ' ' + ca.ca_city
        FROM customer_address ca
        WHERE ca.ca_address_sk = c.c_current_addr_sk
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 2, ''), 'No Address') AS address,
    tc.total_returned,
    tc.return_count,
    tc.max_return_amt
FROM TopReturningCustomers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE tc.rn <= 10
ORDER BY tc.total_returned DESC
OPTION (MAXRECURSION 0);
