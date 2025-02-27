
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_upper,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_lower
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(*) AS count,
        ARRAY_AGG(UPPER(cd_gender)) AS unique_genders,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    cd.count AS customer_count,
    cd.unique_genders,
    cd.avg_dependents,
    cd.marital_statuses,
    (SELECT COUNT(*) FROM customer_info WHERE UPPER(cd_gender) = 'F') AS female_count,
    (SELECT COUNT(*) FROM customer_info WHERE UPPER(cd_gender) = 'M') AS male_count
FROM 
    CustomerInfo ci
JOIN 
    CustomerDemographics cd ON ci.cd_gender = cd.unique_genders[1]
WHERE 
    ci.name_length > 15
ORDER BY 
    ci.full_name;
