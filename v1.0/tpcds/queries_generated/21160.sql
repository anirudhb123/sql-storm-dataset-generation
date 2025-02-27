
WITH CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amt) AS total_return_amt,
        COALESCE(SUM(cr.return_tax), 0) AS total_return_tax,
        COUNT(DISTINCT cr.order_number) AS return_count
    FROM
        catalog_returns cr
    GROUP BY
        cr.returning_customer_sk
),
WebReturns AS (
    SELECT
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_web_return_quantity,
        SUM(wr.return_amt) AS total_web_return_amt,
        COALESCE(SUM(wr.return_tax), 0) AS total_web_return_tax,
        COUNT(DISTINCT wr.order_number) AS web_return_count
    FROM
        web_returns wr
    GROUP BY
        wr.returning_customer_sk
),
CombinedReturns AS (
    SELECT
        COALESCE(cr.returning_customer_sk, wr.returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_return_quantity, 0) + COALESCE(wr.total_web_return_quantity, 0) AS combined_return_quantity,
        COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) AS combined_return_amt,
        COALESCE(cr.total_return_tax, 0) + COALESCE(wr.total_web_return_tax, 0) AS combined_return_tax,
        COALESCE(cr.return_count, 0) + COALESCE(wr.web_return_count, 0) AS combined_return_count
    FROM
        CustomerReturns cr
    FULL OUTER JOIN
        WebReturns wr ON cr.returning_customer_sk = wr.returning_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.combined_return_quantity,
        r.combined_return_amt,
        RANK() OVER (ORDER BY r.combined_return_quantity DESC) AS return_rank
    FROM
        customer c
    JOIN
        CombinedReturns r ON c.c_customer_sk = r.customer_sk
    WHERE
        r.combined_return_quantity > 0
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.combined_return_quantity,
    tc.combined_return_amt,
    CASE
        WHEN tc.return_rank <= 10 THEN 'Top 10'
        WHEN tc.return_rank <= 50 AND tc.return_rank > 10 THEN 'Top 50'
        ELSE 'Others'
    END AS return_group
FROM
    TopCustomers tc
WHERE
    EXISTS (
        SELECT
            1
        FROM
            customer_demographics cd
        WHERE
            cd.cd_demo_sk = c.c_current_cdemo_sk AND
            cd.cd_marital_status = 'M' AND
            cd.cd_gender = 'F'
        HAVING
            SUM(cd.cd_dep_count) >= 2
    )
ORDER BY
    tc.combined_return_quantity DESC,
    tc.c_customer_id;
