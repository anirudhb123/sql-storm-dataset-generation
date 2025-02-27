
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_return_tax), 0) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound) AS income_range
    FROM 
        income_band ib
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.income_range,
    cr.total_returns,
    cr.total_return_amount,
    cr.total_return_tax
FROM 
    CustomerReturns cr
JOIN 
    CustomerDemographics cd ON cr.c_customer_id = cd.cd_demo_sk
LEFT JOIN 
    IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cr.total_returns > 0
ORDER BY 
    cr.total_return_amount DESC
LIMIT 100;
