
WITH CustomerReturns AS (
    SELECT 
        CASE 
            WHEN wr.returning_customer_sk IS NOT NULL THEN wr.returning_customer_sk 
            ELSE sr.returning_customer_sk 
        END AS customer_sk,
        COALESCE(SUM(wr.return_amt), 0) AS total_web_return_amt,
        COALESCE(SUM(sr.return_amt), 0) AS total_store_return_amt,
        COUNT(DISTINCT wr.order_number) AS total_web_returns,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns
    FROM web_returns wr
    FULL OUTER JOIN store_returns sr 
        ON wr.returning_customer_sk = sr.returning_customer_sk
    WHERE 
        wr.returned_date_sk IS NOT NULL OR sr.returned_date_sk IS NOT NULL
    GROUP BY 1
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk 
), RankedReturns AS (
    SELECT 
        cr.customer_sk,
        cr.total_web_return_amt,
        cr.total_store_return_amt,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cr.total_web_return_amt + cr.total_store_return_amt DESC) AS rn
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.customer_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cr.total_web_return_amt + cr.total_store_return_amt) AS avg_total_return,
    MIN(cr.total_web_return_amt + cr.total_store_return_amt) AS min_total_return,
    MAX(cr.total_web_return_amt + cr.total_store_return_amt) AS max_total_return
FROM RankedReturns cr
WHERE cr.rn <= 10
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING AVG(cr.total_web_return_amt + cr.total_store_return_amt) > 50
ORDER BY avg_total_return DESC;
