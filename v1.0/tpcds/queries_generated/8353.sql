
WITH CustomerReturns AS (
    SELECT
        sr_refunded_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt
    FROM
        store_returns
    GROUP BY
        sr_refunded_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM
        customer_demographics
),
DateDetails AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq,
        d_dow,
        d_current_year
    FROM
        date_dim
    WHERE
        d_year >= 2022
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    SUM(sr.total_returned_qty) AS total_returned_qty,
    SUM(sr.total_returned_amt) AS total_returned_amt,
    COUNT(DISTINCT dd.d_date_sk) AS return_years_count
FROM
    customer c
JOIN
    CustomerReturns sr ON c.c_customer_sk = sr.refunded_customer_sk
JOIN
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    DateDetails dd ON sr.returned_date_sk = dd.d_date_sk
WHERE
    cd.cd_purchase_estimate > 500
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate
HAVING
    total_returned_qty > 10
ORDER BY
    total_returned_amt DESC
LIMIT 100;
