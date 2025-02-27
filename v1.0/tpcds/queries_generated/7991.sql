
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= 20210101 AND sr_returned_date_sk <= 20211231
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer_demographics
),
IncomeBands AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        dem.cd_gender,
        dem.cd_marital_status,
        bands.ib_lower_bound,
        bands.ib_upper_bound,
        returns.total_returned_items,
        returns.total_returned_amount,
        returns.return_count
    FROM 
        customer c
        JOIN CustomerDemographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
        JOIN IncomeBands bands ON dem.cd_income_band_sk = bands.ib_income_band_sk
        JOIN CustomerReturns returns ON c.c_customer_sk = returns.sr_customer_sk
)
SELECT 
    *,
    RANK() OVER (PARTITION BY ib_lower_bound, ib_upper_bound ORDER BY total_returned_amount DESC) AS return_rank
FROM 
    CustomerInfo
WHERE 
    total_returned_items > 0
ORDER BY 
    ib_lower_bound, 
    return_rank;
