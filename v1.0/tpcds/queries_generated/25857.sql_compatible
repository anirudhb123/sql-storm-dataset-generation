
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FilteredReturns AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_returns,
        total_return_amount,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_return_amount DESC) AS rnk
    FROM 
        RankedCustomers
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_returns,
    total_return_amount
FROM 
    FilteredReturns
WHERE 
    rnk <= 5
ORDER BY 
    cd_gender, total_return_amount DESC;
