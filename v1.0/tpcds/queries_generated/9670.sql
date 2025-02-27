
WITH CustomerReturnStats AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_return_amount,
        SUM(sr.return_tax) AS total_return_tax,
        SUM(sr.net_loss) AS total_net_loss
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.customer_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        cr.c_customer_id,
        ts.total_returns,
        ts.total_return_quantity,
        ts.total_return_amount,
        ts.total_return_tax,
        ts.total_net_loss,
        ROW_NUMBER() OVER (ORDER BY ts.total_return_amount DESC) AS rank
    FROM
        CustomerReturnStats ts
    JOIN
        customer c ON ts.c_customer_id = c.c_customer_id
    WHERE
        ts.total_returns > 0
)
SELECT
    t_c.c_customer_id,
    t_c.total_returns,
    t_c.total_return_quantity,
    t_c.total_return_amount,
    t_c.total_return_tax,
    t_c.total_net_loss,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country
FROM
    TopCustomers t_c
JOIN
    customer c ON t_c.c_customer_id = c.c_customer_id
WHERE
    t_c.rank <= 10
ORDER BY
    t_c.rank;
