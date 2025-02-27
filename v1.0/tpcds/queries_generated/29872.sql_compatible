
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(sr.ticket_number) AS returns_count,
        SUM(sr.sr_return_amt) AS total_returned,
        AVG(sr.sr_return_quantity) AS avg_returned_quantity
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
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        returns_count,
        total_returned,
        avg_returned_quantity,
        CASE 
            WHEN returns_count > 0 THEN 'Active Returner'
            ELSE 'Non-Returner'
        END AS returner_status
    FROM 
        CustomerDetails
)
SELECT 
    returner_status,
    COUNT(*) AS total_customers,
    AVG(total_returned) AS avg_total_returned,
    AVG(avg_returned_quantity) AS avg_returned_per_order
FROM 
    ReturnAnalysis
GROUP BY 
    returner_status
ORDER BY 
    total_customers DESC;
