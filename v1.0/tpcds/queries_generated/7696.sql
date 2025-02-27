
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS return_count,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.wr_returning_customer_sk,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM RankedReturns cr
    JOIN CustomerDemographics cd ON cr.wr_returning_customer_sk = cd.c_customer_sk
    WHERE cr.rank <= 10
),
ReturnReasons AS (
    SELECT 
        wr.wr_returning_customer_sk,
        r.r_reason_desc,
        COUNT(*) AS reason_count
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY wr.wr_returning_customer_sk, r.r_reason_desc
)
SELECT 
    hrc.wr_returning_customer_sk,
    hrc.total_returned_quantity,
    hrc.total_returned_amount,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.cd_income_band_sk,
    hrc.cd_purchase_estimate,
    rr.r_reason_desc,
    rr.reason_count
FROM HighReturnCustomers hrc
LEFT JOIN ReturnReasons rr ON hrc.wr_returning_customer_sk = rr.wr_returning_customer_sk
ORDER BY hrc.total_returned_amount DESC, rr.reason_count DESC;
