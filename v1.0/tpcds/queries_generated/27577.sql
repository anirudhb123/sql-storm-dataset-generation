
WITH CustomerFullNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca_city,
        ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
EmailDomainCounts AS (
    SELECT 
        SUBSTRING_INDEX(c_email_address, '@', -1) AS email_domain,
        COUNT(*) AS customer_count
    FROM 
        CustomerFullNames
    GROUP BY 
        email_domain
),
GenderStatistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CustomerFullNames
    GROUP BY 
        cd_gender
),
MaritalStatusEducation AS (
    SELECT 
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        CustomerFullNames
    GROUP BY 
        cd_marital_status, cd_education_status
)
SELECT 
    'Email Domain Statistics' AS type,
    email_domain,
    customer_count
FROM 
    EmailDomainCounts
UNION ALL
SELECT 
    'Gender Statistics' AS type,
    cd_gender AS email_domain,
    gender_count
FROM 
    GenderStatistics
UNION ALL
SELECT 
    'Marital Status and Education' AS type,
    CONCAT(cd_marital_status, ' - ', cd_education_status) AS email_domain,
    demographic_count
FROM 
    MaritalStatusEducation
ORDER BY 
    type, email_domain;
