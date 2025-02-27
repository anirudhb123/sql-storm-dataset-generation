
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
HighReturningCustomers AS (
    SELECT
        c_customer_id,
        return_count,
        total_return_amt
    FROM
        CustomerReturns
    WHERE
        return_count > (
            SELECT
                AVG(return_count)
            FROM
                CustomerReturns
        )
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics cd
    WHERE
        cd_cd_demo_sk IN (
            SELECT 
                c.c_current_cdemo_sk 
            FROM 
                customer c
            WHERE 
                c.c_customer_id IN (SELECT c_customer_id FROM HighReturningCustomers)
        )
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    hrc.c_customer_id,
    hrc.return_count,
    hrc.total_return_amt,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.avg_purchase_estimate, 0) AS avg_purchase_estimate
FROM
    HighReturningCustomers hrc
LEFT JOIN
    CustomerDemographics cd ON hrc.c_customer_id = (
        SELECT 
            c.c_customer_id
        FROM 
            customer c
        WHERE 
            c.c_current_cdemo_sk IN (
                SELECT 
                    cd.cd_demo_sk
                FROM 
                    customer_demographics cd
                WHERE 
                    cd.cd_gender IS NOT NULL
            )
        LIMIT 1
    )
ORDER BY
    hrc.total_return_amt DESC
LIMIT 100;
