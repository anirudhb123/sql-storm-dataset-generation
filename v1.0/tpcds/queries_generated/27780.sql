
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_tax) AS total_return_tax
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ReturnAnalysis AS (
    SELECT 
        cs.full_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        cs.total_returns,
        cs.total_return_amt,
        cs.total_return_tax,
        CASE 
            WHEN cs.total_returns = 0 THEN 'No Returns'
            WHEN cs.total_return_amt > 1000 THEN 'High Returner'
            ELSE 'Regular Returner'
        END AS return_category
    FROM 
        CustomerStats cs
)
SELECT 
    ra.return_category,
    COUNT(ra.full_name) AS num_customers,
    AVG(ra.total_return_amt) AS avg_return_amt,
    AVG(ra.total_return_tax) AS avg_return_tax,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.cd_education_status
FROM 
    ReturnAnalysis ra
GROUP BY 
    ra.return_category, ra.cd_gender, ra.cd_marital_status, ra.cd_education_status
ORDER BY 
    ra.return_category, num_customers DESC;
