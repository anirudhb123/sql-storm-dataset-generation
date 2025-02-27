
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
email_analysis AS (
    SELECT 
        full_name,
        email_address,
        LENGTH(email_address) AS email_length,
        LOWER(email_address) AS email_lower,
        UPPER(email_address) AS email_upper,
        REGEXP_REPLACE(email_address, '@.*', '') AS email_prefix,
        REGEXP_REPLACE(email_address, '.*@', '') AS email_domain
    FROM 
        customer_info
),
demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_dep_employed_count) AS avg_employed_dependents,
        AVG(cd_dep_college_count) AS avg_college_dependents
    FROM 
        customer_info
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    e.full_name,
    e.email_address,
    e.email_length,
    e.email_lower,
    e.email_upper,
    e.email_prefix,
    e.email_domain,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.total_customers,
    ds.avg_dependents,
    ds.avg_employed_dependents,
    ds.avg_college_dependents
FROM 
    email_analysis e
JOIN 
    demographic_summary ds ON e.cd_gender = ds.cd_gender AND e.cd_marital_status = ds.cd_marital_status
ORDER BY 
    e.email_length DESC
LIMIT 100;
