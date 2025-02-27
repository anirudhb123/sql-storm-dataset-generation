
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate IS NOT NULL
),
QualifiedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity
    FROM
        customer c
    LEFT JOIN
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'S') OR
        (cd.cd_gender = 'M' AND cd.cd_purchase_estimate > 500)
),
TopCustomers AS (
    SELECT
        q.*,
        DENSE_RANK() OVER (ORDER BY q.total_return_amount DESC) AS return_rank
    FROM
        QualifiedCustomers q
)
SELECT
    ROW_NUMBER() OVER (ORDER BY tc.total_return_quantity DESC) AS rank,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returns,
    tc.total_return_amount,
    tc.total_return_quantity,
    CASE
        WHEN tc.total_return_amount > 1000 THEN 'High Value'
        WHEN tc.total_return_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM customer_address ca
            WHERE ca.ca_address_sk = c.c_current_addr_sk AND ca.ca_city IS NOT NULL
        ) THEN 'Has Valid Address'
        ELSE 'No Valid Address'
    END AS address_status
FROM
    TopCustomers tc
WHERE
    tc.return_rank <= 10
ORDER BY
    tc.total_return_quantity DESC,
    tc.c_last_name ASC;
