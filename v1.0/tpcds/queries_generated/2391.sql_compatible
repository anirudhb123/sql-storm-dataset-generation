
WITH RankedReturns AS (
    SELECT
        wr.returning_customer_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC) AS rnk
    FROM web_returns wr
    WHERE wr.return_quantity > 0
), CustomerStats AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(COALESCE(sr.return_amt, 0)) AS total_return_amount,
        AVG(wr.return_quantity) AS avg_return_quantity
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN RankedReturns rr ON c.c_customer_sk = rr.returning_customer_sk AND rr.rnk <= 5
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), IncomeDistribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN cs.total_returns > 0 THEN 1 ELSE 0 END) AS return_customers
    FROM household_demographics h
    JOIN CustomerStats cs ON h.hd_demo_sk = cs.c_customer_id
    GROUP BY h.hd_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(id.customer_count, 0) AS total_customers,
    COALESCE(id.return_customers, 0) AS total_customers_with_returns,
    COALESCE(id.return_customers, 0) * 100.0 / NULLIF(id.customer_count, 0) AS return_customer_percentage
FROM income_band ib
LEFT JOIN IncomeDistribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
ORDER BY ib.ib_income_band_sk;
