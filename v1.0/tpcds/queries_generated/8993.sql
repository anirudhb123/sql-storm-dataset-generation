
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        customer c
    JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM
        customer_demographics cd
),
HighValueCustomers AS (
    SELECT
        cr.c_customer_id
    FROM
        CustomerReturns cr
    JOIN
        CustomerDemographics cd ON cr.c_customer_id = cd.cd_demo_sk
    WHERE
        cr.total_returned_amount < 500
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cr.total_returned_quantity,
    cr.total_returned_amount
FROM
    CustomerReturns cr
JOIN
    customer c ON c.c_customer_id = cr.c_customer_id
WHERE
    cr.c_customer_id IN (SELECT c_customer_id FROM HighValueCustomers)
ORDER BY
    total_returned_quantity DESC
LIMIT 10;
