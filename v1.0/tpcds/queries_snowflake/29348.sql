
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn,
        c.c_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAgeGroups AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN YEAR(CURRENT_DATE()) - c_birth_year < 30 THEN 'Under 30'
            WHEN YEAR(CURRENT_DATE()) - c_birth_year BETWEEN 30 AND 50 THEN '30-50'
            ELSE 'Over 50'
        END AS age_group
    FROM 
        RankedCustomers
)
SELECT 
    age_group,
    cd_gender,
    COUNT(*) AS count,
    LISTAGG(full_name, ', ' ORDER BY full_name) AS customer_names
FROM 
    CustomerAgeGroups
GROUP BY 
    age_group, cd_gender
ORDER BY 
    age_group, cd_gender;
