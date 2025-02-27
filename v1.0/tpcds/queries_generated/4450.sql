
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M'
),
RecentReturns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count
    FROM
        store_returns sr
    WHERE
        sr.sr_returned_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_date = CURRENT_DATE
        )
    GROUP BY
        sr.sr_customer_sk
),
CustomerReturnStats AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt,
        COALESCE(rr.return_count, 0) AS return_count,
        NULLIF(rc.rnk, 0) AS rank
    FROM
        RankedCustomers rc
    LEFT JOIN
        RecentReturns rr ON rc.c_customer_sk = rr.sr_customer_sk
)
SELECT
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_return_amt,
    cr.return_count,
    CASE
        WHEN cr.rank IS NOT NULL THEN 'Ranked Customer'
        ELSE 'Unranked Customer'
    END AS customer_type,
    CONCAT('Total Returns:', COALESCE(cr.total_return_amt, 'No Returns')) AS return_message
FROM
    CustomerReturnStats cr
WHERE
    cr.total_return_amt > 0 OR cr.return_count > 0
ORDER BY
    cr.total_return_amt DESC,
    cr.return_count DESC
LIMIT 100;
