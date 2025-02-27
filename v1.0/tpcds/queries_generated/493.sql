
WITH TotalReturns AS (
    SELECT 
        COALESCE(wr_returned_date_sk, sr_returned_date_sk) AS return_date,
        COALESCE(ws_bill_customer_sk, ss_customer_sk) AS customer_sk,
        SUM(COALESCE(wr_return_quantity, sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(wr_return_amt, sr_return_amt, 0)) AS total_returned_amount
    FROM 
        web_returns wr
    FULL OUTER JOIN 
        store_returns sr ON wr_returning_customer_sk = sr_customer_sk
    GROUP BY 
        return_date, customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT(cd.cd_demo_sk)) AS count_demo
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
ReturnsWithDemographics AS (
    SELECT 
        tr.return_date,
        tr.customer_sk,
        tr.total_returned_quantity,
        tr.total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        TotalReturns tr
    LEFT JOIN 
        CustomerDemographics cd ON tr.customer_sk = cd.c_customer_sk
    LEFT JOIN 
        household_demographics ib ON cd.cd_income_band_sk = ib.hd_income_band_sk
)
SELECT 
    rwd.return_date,
    rwd.customer_sk,
    rwd.total_returned_quantity,
    rwd.total_returned_amount,
    rwd.cd_gender,
    rwd.cd_marital_status,
    CASE 
        WHEN rwd.total_returned_quantity IS NULL THEN 'Not Found'
        ELSE 'Found'
    END AS return_status,
    RANK() OVER (PARTITION BY rwd.customer_sk ORDER BY rwd.total_returned_amount DESC) AS rank_return_amount
FROM 
    ReturnsWithDemographics rwd
WHERE 
    ((rwd.cd_gender = 'M' AND rwd.total_returned_amount > 100)
    OR (rwd.cd_gender = 'F' AND rwd.total_returned_amount <= 100)
    OR (rwd.total_returned_quantity IS NULL))
ORDER BY 
    rwd.return_date DESC, rwd.total_returned_amount DESC;
