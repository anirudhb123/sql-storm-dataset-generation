
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY c.c_customer_sk) AS row_num
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CitySummary AS (
    SELECT 
        ci.ca_city,
        ci.ca_state,
        COUNT(*) AS customer_count,
        LISTAGG(ci.full_name, ', ') WITHIN GROUP (ORDER BY ci.full_name) AS customer_names,
        LISTAGG(ci.cd_gender, ', ') WITHIN GROUP (ORDER BY ci.cd_gender) AS genders,
        LISTAGG(ci.cd_marital_status, ', ') WITHIN GROUP (ORDER BY ci.cd_marital_status) AS marital_statuses,
        LISTAGG(ci.cd_education_status, ', ') WITHIN GROUP (ORDER BY ci.cd_education_status) AS education_statuses
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.ca_city, ci.ca_state
)
SELECT 
    cs.ca_city,
    cs.ca_state,
    cs.customer_count,
    cs.customer_names,
    cs.genders,
    cs.marital_statuses,
    cs.education_statuses,
    CASE 
        WHEN cs.customer_count > 100 THEN 'High Density'
        WHEN cs.customer_count BETWEEN 50 AND 100 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS density_category
FROM 
    CitySummary cs
WHERE 
    LENGTH(cs.ca_city) > 4
ORDER BY 
    cs.customer_count DESC;
