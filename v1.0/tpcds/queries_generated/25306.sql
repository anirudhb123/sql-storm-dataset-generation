
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
DemographicsInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        CONCAT(cd_education_status, ' - ', cd_credit_rating) AS education_credit,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_demo_sk) AS demographics_rank
    FROM 
        customer_demographics
),
CombinedInfo AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.education_credit
    FROM 
        AddressInfo a
    JOIN 
        DemographicsInfo d ON a.address_rank = d.demographics_rank
),
DateRange AS (
    SELECT 
        d_date
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.education_credit,
    COUNT(*) AS record_count,
    COUNT(DISTINCT ci.cd_gender) AS unique_genders,
    COUNT(DISTINCT ci.cd_marital_status) AS unique_marital_status
FROM 
    CombinedInfo ci
JOIN 
    DateRange dr ON dr.d_date IS NOT NULL
GROUP BY 
    ci.ca_city, ci.ca_state, ci.full_address, ci.cd_gender, ci.cd_marital_status, ci.education_credit
ORDER BY 
    record_count DESC;
