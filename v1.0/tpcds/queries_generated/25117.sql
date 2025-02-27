
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
ReturnDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cr.total_return_amt) AS avg_return_amt,
        AVG(cr.return_count) AS avg_return_count
    FROM 
        CustomerReturns cr
    JOIN 
        customer_demographics cd ON cr.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ReturnStringMetrics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        STRING_AGG(CONCAT('Gender: ', cd.cd_gender, 
                         ', Marital Status: ', cd.cd_marital_status, 
                         ', Avg Return Amt: ', CAST(AVG(cr.total_return_amt) AS VARCHAR), 
                         ', Avg Return Count: ', CAST(AVG(cr.return_count) AS VARCHAR)), 
                 '; ') AS customer_report
    FROM 
        ReturnDemographics cr
    JOIN 
        customer_demographics cd ON cr.cd_gender = cd.cd_gender 
                                  AND cr.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    customer_report
FROM 
    ReturnStringMetrics
WHERE 
    LENGTH(customer_report) > 100
ORDER BY 
    cd_gender, cd_marital_status;
