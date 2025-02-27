
WITH Ranked_Customer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_by_age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Filtered_Customers AS (
    SELECT 
        full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        Ranked_Customer
    WHERE 
        rank_by_age <= 10
),
Concatenated_Customers AS (
    SELECT 
        STRING_AGG(full_name, ', ') AS top_customers, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        Filtered_Customers
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    top_customers
FROM 
    Concatenated_Customers
ORDER BY 
    cd_gender, cd_marital_status, cd_education_status;
