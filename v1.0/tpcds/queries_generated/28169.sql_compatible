
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_returned_amount
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ReturnAnalysis AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        total_returns,
        total_returned_amount,
        CASE 
            WHEN total_returns > 10 THEN 'High Return Customer'
            WHEN total_returns BETWEEN 5 AND 10 THEN 'Moderate Return Customer'
            ELSE 'Low Return Customer'
        END AS return_category
    FROM 
        RankedCustomers
)
SELECT 
    return_category,
    COUNT(*) AS number_of_customers,
    AVG(total_returned_amount) AS average_returned_amount
FROM 
    ReturnAnalysis
GROUP BY 
    return_category
ORDER BY 
    number_of_customers DESC;
