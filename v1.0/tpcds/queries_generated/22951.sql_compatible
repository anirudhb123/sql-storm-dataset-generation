
WITH RankedReturns AS (
    SELECT
        sr_returning_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_amt DESC) AS rn,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_returning_customer_sk) AS total_returned,
        NULLIF(SUM(sr_return_amt) OVER (PARTITION BY sr_returning_customer_sk), 0) AS total_amount_returned
    FROM
        store_returns
    WHERE
        sr_returned_date_sk IS NOT NULL
),
HighReturnCustomers AS (
    SELECT
        sr_returning_customer_sk,
        total_returned,
        CASE
            WHEN total_returned > 100 THEN 'High'
            WHEN total_returned BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM
        RankedReturns
    WHERE
        rn = 1
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_city,
        h.hd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FinalAnalysis AS (
    SELECT
        cd.c_customer_id,
        cd.cd_gender,
        cd.ca_city,
        hrc.return_category,
        cd.dependents,
        COALESCE(MAX(rr.total_returned), 0) AS max_returns,
        COALESCE(MIN(rr.total_amount_returned), 0) AS min_return_amount,
        AVG(rr.total_returned) FILTER (WHERE rr.total_returned > 0) AS avg_positive_returns
    FROM
        CustomerDetails cd
    LEFT JOIN HighReturnCustomers hrc ON cd.c_customer_id = hrc.sr_returning_customer_sk
    LEFT JOIN RankedReturns rr ON cd.c_customer_id = rr.sr_returning_customer_sk
    GROUP BY
        cd.c_customer_id, cd.cd_gender, cd.ca_city, hrc.return_category, cd.dependents
)
SELECT
    fa.*,
    ROUND((fa.max_returns - fa.min_return_amount) / NULLIF(NULLIF(fa.max_returns, 0), 0.0001), 2) AS return_variability
FROM
    FinalAnalysis fa
ORDER BY
    fa.avg_positive_returns DESC, fa.return_category, fa.c_customer_id;
