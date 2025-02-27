
WITH CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
StoreSalesSummary AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales_amt,
        AVG(ss_net_profit) AS avg_net_profit
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_purchase_estimate
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
IncomeBand AS (
    SELECT
        ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM
        household_demographics
    GROUP BY
        ib_income_band_sk
    HAVING
        COUNT(*) > 10
),
SalesAndReturns AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales_amt,
        COALESCE(cr_return_count, 0) AS total_return_qty
    FROM
        catalog_sales cs
    LEFT JOIN (
        SELECT
            cr_returning_customer_sk,
            SUM(cr_return_quantity) AS cr_return_count
        FROM
            catalog_returns
        GROUP BY
            cr_returning_customer_sk
    ) cr ON cs_bill_customer_sk = cr_returning_customer_sk
    GROUP BY
        cs_bill_customer_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    Cf.total_sales_amt,
    ct.total_return_amt,
    CASE
        WHEN Cf.total_sales_amt > 0 THEN (ct.total_return_amt / Cf.total_sales_amt) * 100
        ELSE NULL
    END AS return_percentage,
    ib.ib_income_band_sk,
    ib.customer_count
FROM
    CustomerDemographics cd
JOIN
    SalesAndReturns Cf ON cd.cd_demo_sk = Cf.customer_sk
LEFT JOIN
    CustomerReturns ct ON cf.customer_sk = ct.wr_returning_customer_sk
FULL OUTER JOIN
    IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
WHERE
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
AND
    (cf.total_sales_amt > 500 OR cf.total_return_qty <= 5)
ORDER BY
    cd.cd_demo_sk DESC
LIMIT 100;
