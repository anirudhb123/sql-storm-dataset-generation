
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr.return_amt) DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FrequentReturns AS (
    SELECT
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_returns,
        total_returned_amt,
        rn
    FROM 
        RankedCustomers
    WHERE 
        rn <= 5
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS frequency,
    AVG(total_returns) AS avg_returns,
    SUM(total_returned_amt) AS total_returned_amount
FROM 
    FrequentReturns
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    total_returned_amount DESC;
