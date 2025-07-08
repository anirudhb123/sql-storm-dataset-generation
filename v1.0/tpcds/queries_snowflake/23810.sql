
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_amount_refunded
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_returning_customer_sk
), ReturnReasons AS (
    SELECT 
        cr_reason_sk, 
        cr_returning_customer_sk,
        COUNT(*) AS reason_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_reason_sk, cr_returning_customer_sk
), DemographyWithReturns AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cust.total_returns, 0) AS total_returns,
        COALESCE(cust.total_amount_refunded, 0) AS total_amount_refunded,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_demo_sk ORDER BY COALESCE(cust.total_amount_refunded, 0) DESC) AS rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerReturns cust ON cd.cd_demo_sk = cust.cr_returning_customer_sk
), IncomeBandAnalysis AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT dem.cd_demo_sk) AS customer_count,
        MAX(dem.total_returns) AS max_returns
    FROM 
        household_demographics h
    LEFT JOIN 
        DemographyWithReturns dem ON dem.cd_demo_sk = h.hd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
), AggregatedReturns AS (
    SELECT 
        d.d_year,
        SUM(dem.total_returns) AS yearly_returns,
        SUM(dem.total_amount_refunded) AS total_refunded
    FROM 
        DemographyWithReturns dem
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(cr_returned_date_sk) FROM catalog_returns cr WHERE cr_returning_customer_sk = dem.cd_demo_sk)
    GROUP BY 
        d.d_year
)
SELECT 
    ib.ib_income_band_sk,
    ia.customer_count,
    ia.max_returns,
    ar.yearly_returns,
    ar.total_refunded
FROM 
    IncomeBandAnalysis ia
JOIN 
    income_band ib ON ia.hd_income_band_sk = ib.ib_income_band_sk
FULL OUTER JOIN 
    AggregatedReturns ar ON ar.d_year = 2023
ORDER BY 
    ib.ib_income_band_sk, ia.customer_count DESC, ar.total_refunded DESC
LIMIT 100;
