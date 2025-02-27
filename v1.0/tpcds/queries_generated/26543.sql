
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        c.c_birth_year,
        DATEDIFF(CURRENT_DATE, DATE(CONCAT(c.c_birth_year, '-', c.c_birth_month, '-', c.c_birth_day))) AS age
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FilteredCustomers AS (
    SELECT
        *,
        CASE
            WHEN age < 25 THEN 'Young Adult'
            WHEN age BETWEEN 25 AND 44 THEN 'Adult'
            WHEN age BETWEEN 45 AND 64 THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_group
    FROM 
        CustomerData
    WHERE 
        cd_gender = 'F' AND ca_state = 'CA'
),
Statistics AS (
    SELECT 
        age_group,
        COUNT(*) AS num_customers,
        AVG(c_birth_year) AS avg_birth_year
    FROM 
        FilteredCustomers
    GROUP BY 
        age_group
)
SELECT 
    age_group,
    num_customers,
    avg_birth_year,
    CONCAT(num_customers, ' customers in ', age_group) AS summary
FROM 
    Statistics
ORDER BY 
    num_customers DESC;
