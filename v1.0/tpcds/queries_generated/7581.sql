
WITH RankedReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.item_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        wr.return_amt_inc_tax,
        wr.returning_customer_sk,
        COUNT(*) OVER (PARTITION BY wr.returning_customer_sk) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim d WHERE d.d_date = '2023-01-01') 
        AND (SELECT MAX(d_date_sk) FROM date_dim d WHERE d.d_date = '2023-12-31')
),
HighReturnCustomers AS (
    SELECT 
        returning_customer_sk,
        SUM(return_quantity) AS total_return_quantity,
        SUM(return_amt) AS total_return_amt
    FROM 
        RankedReturns
    GROUP BY 
        returning_customer_sk
    HAVING 
        SUM(return_quantity) > 10  -- Select customers who have returned more than 10 items
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        h.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(r.total_return_quantity) AS total_returned_items,
    SUM(r.total_return_amt) AS total_returned_value
FROM 
    CustomerDemographics cd
JOIN 
    HighReturnCustomers r ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = r.returning_customer_sk)
JOIN 
    customer c ON c.c_customer_id = r.returning_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_returned_value DESC
LIMIT 50;
