
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'NA') AS buy_potential,
        hd.hd_dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
ReturnSummary AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.buy_potential,
        SUM(cr.return_count) AS total_returns,
        SUM(cr.total_return_amount) AS total_return_value,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(cr.total_return_amount) DESC) AS gender_rank
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.buy_potential
)
SELECT 
    r.cd_gender,
    COUNT(*) AS num_customers,
    AVG(r.total_return_value) AS avg_return_value,
    SUM(r.total_returns) AS total_returned_items
FROM 
    ReturnSummary r
WHERE 
    r.gender_rank <= 5
GROUP BY 
    r.cd_gender
ORDER BY 
    num_customers DESC;
