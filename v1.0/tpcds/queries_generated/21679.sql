
WITH CustomerReturns AS (
    SELECT
        sr_store_sk,
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns
    GROUP BY
        sr_store_sk,
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT
        cr.sr_store_sk,
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amount,
        cr.total_return_tax,
        COALESCE(c.c_birth_year, 0) AS birth_year
    FROM
        CustomerReturns cr
    LEFT JOIN
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE
        cr.total_return_amount > 1000
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM
        customer_demographics cd
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopStores AS (
    SELECT
        sr.s_store_sk,
        SUM(sr.ss_net_profit) AS total_net_profit
    FROM
        store_sales sr
    GROUP BY
        sr.s_store_sk
    HAVING
        SUM(sr.ss_net_profit) > 50000
),
FinalResults AS (
    SELECT
        cr.sr_store_sk,
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amount,
        cr.total_return_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ib_income_band_sk,
        ts.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cr.sr_store_sk ORDER BY cr.total_return_amount DESC) AS rn
    FROM
        HighReturnCustomers cr
    JOIN
        CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    JOIN
        TopStores ts ON cr.sr_store_sk = ts.s_store_sk
)
SELECT
    fr.sr_store_sk,
    fr.sr_customer_sk,
    fr.return_count,
    fr.total_return_amount,
    fr.total_return_tax,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.ib_income_band_sk,
    fr.total_net_profit
FROM
    FinalResults fr
WHERE
    fr.rn = 1
    AND fr.return_count > (SELECT AVG(return_count) FROM CustomerReturns)
ORDER BY
    fr.total_return_amount DESC;
