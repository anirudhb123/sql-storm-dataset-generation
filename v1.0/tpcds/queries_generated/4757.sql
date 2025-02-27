
WITH CustomerReturns AS (
    SELECT
        cs_ship_customer_sk AS customer_sk,
        COUNT(DISTINCT wr_return_number) AS web_returns_count,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS store_returns_count,
        SUM(sr_return_amt_inc_tax) AS total_store_return_amt
    FROM web_returns wr
    FULL OUTER JOIN store_returns sr ON wr_returning_customer_sk = sr_returning_customer_sk
    GROUP BY cs_ship_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
AggregateReturns AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.web_returns_count, 0) AS web_returns_count,
        COALESCE(cr.store_returns_count, 0) AS store_returns_count,
        COALESCE(cr.total_web_return_amt, 0) AS total_web_running_amt,
        COALESCE(cr.total_store_return_amt, 0) AS total_store_running_amt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cr.total_web_return_amt, 0) + COALESCE(cr.total_store_return_amt, 0) DESC) AS rn
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.customer_sk
)
SELECT
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.cd_gender,
    a.cd_marital_status,
    a.web_returns_count,
    a.store_returns_count,
    a.total_web_return_amt,
    a.total_store_return_amt
FROM AggregateReturns a
WHERE a.rn <= 5
  AND (a.cd_gender = 'F' AND a.total_web_return_amt > 1000
       OR a.cd_gender = 'M' AND a.total_store_return_amt > 500)
ORDER BY a.total_web_return_amt DESC, a.total_store_return_amt DESC;
