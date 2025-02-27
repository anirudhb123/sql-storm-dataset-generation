
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT cr.order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_customer_sk = d.cd_demo_sk
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.lower_bound,
        ib.upper_bound
    FROM 
        income_band ib
),
ReturnAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.lower_bound,
        ib.upper_bound,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(cr.return_count, 0) AS return_count
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.returning_customer_sk
    LEFT JOIN 
        IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ra.cd_gender,
    ra.cd_marital_status,
    ra.lower_bound,
    ra.upper_bound,
    AVG(ra.total_returned_quantity) AS avg_returned_quantity,
    AVG(ra.total_returned_amount) AS avg_returned_amount,
    SUM(ra.return_count) AS total_return_count
FROM 
    ReturnAnalysis ra
GROUP BY 
    ra.cd_gender, 
    ra.cd_marital_status, 
    ra.lower_bound, 
    ra.upper_bound
ORDER BY 
    ra.cd_gender, 
    ra.cd_marital_status;
