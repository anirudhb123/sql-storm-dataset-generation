
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Male'
        END AS gender,
        cd_income_band_sk,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_purchase_estimate > 1000
),
ReturnAnalysis AS (
    SELECT
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.gender,
        hvc.cd_income_band_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM HighValueCustomers hvc
    LEFT JOIN CustomerReturns cr ON hvc.c_customer_sk = cr.sr_customer_sk
),
RankedReturns AS (
    SELECT
        ra.*,
        RANK() OVER (PARTITION BY ra.cd_income_band_sk ORDER BY ra.total_return_value DESC) AS return_rank
    FROM ReturnAnalysis ra
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.gender,
    r.total_returns,
    r.total_return_value,
    ib.ib_lower_bound AS income_lower_bound,
    ib.ib_upper_bound AS income_upper_bound,
    r.return_rank
FROM RankedReturns r
JOIN income_band ib ON r.cd_income_band_sk = ib.ib_income_band_sk
WHERE r.return_rank <= 5
ORDER BY r.cd_income_band_sk, r.total_return_value DESC;
