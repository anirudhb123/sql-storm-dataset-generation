
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(cr.returned_date_sk) AS total_returns,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amount) AS total_returned_amount
    FROM
        customer c
    JOIN
        catalog_returns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_returns,
        total_returned_quantity,
        total_returned_amount,
        RANK() OVER (ORDER BY total_returned_amount DESC) AS return_rank
    FROM
        CustomerReturns
)
SELECT 
    tc.c_customer_id,
    tc.total_returns,
    tc.total_returned_quantity,
    tc.total_returned_amount,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
FROM
    TopCustomers tc
JOIN
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
WHERE
    tc.return_rank <= 10
ORDER BY
    tc.total_returned_amount DESC;
