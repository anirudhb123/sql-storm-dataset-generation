
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS return_count
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM
        customer_demographics
),
IncomeBand AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM
        income_band
),
DateDetails AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        d_dow,
        d_current_year,
        COUNT(d_date) AS total_days
    FROM
        date_dim
    GROUP BY
        d_year, d_month_seq, d_week_seq, d_dow, d_current_year
),
SalesData AS (
    SELECT
        cs_ship_date_sk,
        SUM(cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM
        catalog_sales
    WHERE
        cs_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY
        cs_ship_date_sk
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS returning_customers,
    SUM(cr.total_return_amount) AS total_returns,
    SUM(sd.total_sales) AS total_sales,
    COUNT(DISTINCT sd.total_orders) AS total_orders,
    AVG(CASE WHEN ib.ib_lower_bound IS NOT NULL THEN (ib.ib_lower_bound + ib.ib_upper_bound) / 2 ELSE NULL END) AS avg_income_band
FROM
    CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.cr_returning_customer_sk = cd.cd_demo_sk
    LEFT JOIN IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN SalesData sd ON sd.cs_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow = 5)
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY
    total_returns DESC, total_sales DESC
LIMIT 10;
