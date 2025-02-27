
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
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
        cd_income_band_sk,
        cd_dep_count,
        cd_credit_rating
    FROM
        customer_demographics
),
IncomeBands AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM
        income_band
),
EligibleCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.ca_address_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(r.return_count) AS returns,
        SUM(r.total_return_amount) AS amount_returned,
        ib.ib_income_band_sk,
        CASE 
            WHEN amount_returned IS NULL THEN 0
            ELSE amount_returned
        END AS adjusted_return_amount
    FROM
        customer c
    LEFT JOIN
        CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
    LEFT JOIN
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        IncomeBands ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.ca_address_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
RankedCustomers AS (
    SELECT
        ec.*,
        RANK() OVER (PARTITION BY ec.ib_income_band_sk ORDER BY ec.adjusted_return_amount DESC) AS return_rank
    FROM
        EligibleCustomers ec
)
SELECT
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.ib_income_band_sk,
    rc.adjusted_return_amount,
    rc.return_rank
FROM
    RankedCustomers rc
WHERE
    rc.return_rank <= 10
ORDER BY
    rc.ib_income_band_sk, rc.return_rank;
