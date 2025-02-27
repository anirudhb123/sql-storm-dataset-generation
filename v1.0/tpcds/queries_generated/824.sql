
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_quantity) AS total_return_qty
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
    WHERE 
        ib.ib_upper_bound > 50000
),
AggregatedReturns AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.total_returns) AS returns_count,
        SUM(cr.total_return_amt) AS returns_value
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
    WHERE 
        cd.cd_dep_count IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    CONCAT(CASE WHEN cr.cd_gender = 'M' THEN 'Mr. ' ELSE 'Ms. ' END, c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ab.ib_lower_bound AS income_lower,
    ab.ib_upper_bound AS income_upper,
    ar.returns_count,
    ar.returns_value
FROM 
    AggregatedReturns ar
JOIN 
    IncomeBand ab ON ab.ib_income_band_sk = (SELECT cd.cd_income_band_sk FROM CustomerDemographics cd WHERE cd.c_customer_sk = ar.c_customer_sk LIMIT 1)
LEFT JOIN 
    customer c ON c.c_customer_sk = ar.c_customer_sk
ORDER BY 
    returns_value DESC
LIMIT 100;
