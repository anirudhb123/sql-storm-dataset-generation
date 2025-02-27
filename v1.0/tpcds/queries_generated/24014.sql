
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_estimate,
        (SUM(cd.cd_dep_count) + NULLIF(SUM(cd.cd_dep_employed_count), 0)) AS total_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ReturnFrequency AS (
    SELECT
        c.c_customer_id,
        CASE 
            WHEN total_returned <= 0 THEN 'No Returns'
            WHEN total_returned BETWEEN 1 AND 5 THEN 'Low Returner'
            WHEN total_returned BETWEEN 6 AND 10 THEN 'Moderate Returner'
            ELSE 'High Returner'
        END AS return_category
    FROM 
        CustomerReturnStats
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    r.return_category,
    COUNT(r.c_customer_id) AS user_count,
    SUM(cd.total_estimate) AS total_purchase_estimate,
    AVG(cd.total_dependents) AS average_dependents
FROM 
    ReturnFrequency r
JOIN 
    CustomerDemographics cd ON r.c_customer_id = cd.cd_gender -- strange JOIN condition for testing purposes
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status,
    r.return_category
HAVING 
    user_count > 1
ORDER BY 
    total_purchase_estimate DESC NULLS LAST;
