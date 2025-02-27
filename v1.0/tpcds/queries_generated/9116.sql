
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cr.total_returned_quantity,
        cr.total_returned_amount
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
)
SELECT 
    di.d_year,
    di.d_month_seq,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    AVG(ci.total_returned_quantity) AS avg_returned_quantity,
    AVG(ci.total_returned_amount) AS avg_returned_amount,
    COUNT(ci.c_customer_sk) AS customer_count
FROM 
    CombinedData ci
JOIN 
    DateInfo di ON ci.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = di.d_year))
GROUP BY 
    di.d_year, di.d_month_seq, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
ORDER BY 
    di.d_year, di.d_month_seq;
