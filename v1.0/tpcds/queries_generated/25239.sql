
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_birth_country,
        COUNT(DISTINCT sr.ticket_number) AS returns_count,
        SUM(sr.return_amt) AS total_returns,
        SUM(sr.return_tax) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, 
        c.c_birth_country
),
TopCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        c_birth_country,
        returns_count,
        total_returns,
        total_return_tax,
        RANK() OVER (ORDER BY total_returns DESC) AS rank
    FROM 
        CustomerStats
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    cd_purchase_estimate, 
    c_birth_country, 
    returns_count, 
    total_returns,
    total_return_tax
FROM 
    TopCustomers
WHERE 
    rank <= 10
ORDER BY 
    total_returns DESC;
