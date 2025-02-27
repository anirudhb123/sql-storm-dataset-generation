
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        CustomerDemographics cd
    JOIN 
        household_demographics hd ON cd.cd_income_band_sk = hd.hd_income_band_sk 
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk 
    GROUP BY 
        ib.ib_income_band_sk
),
ReturnStatistics AS (
    SELECT 
        ib.ib_income_band_sk,
        COALESCE(cr.return_count, 0) AS store_return_count,
        COALESCE(wr.web_return_count, 0) AS web_return_count,
        (COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_web_return_amount, 0)) AS total_return_amount
    FROM 
        IncomeBand ib
    LEFT JOIN 
        CustomerReturns cr ON ib.ib_income_band_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebReturns wr ON ib.ib_income_band_sk = wr.wr_returning_customer_sk
)
SELECT 
    r.ib_income_band_sk,
    r.store_return_count,
    r.web_return_count,
    r.total_return_amount,
    r.total_return_amount / NULLIF((SELECT SUM(cd.cd_purchase_estimate) FROM CustomerDemographics cd WHERE cd.cd_income_band_sk = r.ib_income_band_sk), 0) AS return_ratio
FROM 
    ReturnStatistics r
ORDER BY 
    r.total_return_amount DESC;
