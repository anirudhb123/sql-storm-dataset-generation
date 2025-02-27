
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
DemographicInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
DateInfo AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(*) AS count_date
    FROM 
        date_dim
    GROUP BY 
        d_year, 
        d_month_seq
),
CombinedInfo AS (
    SELECT 
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.demographic_count,
        di_gender_percentage.gender_percentage,
        di_marital_percentage.marital_percentage,
        di_education_percentage.education_percentage,
        di_education_percentage.education_status 
    FROM 
        AddressInfo ai
    JOIN 
        DemographicInfo di ON ai.ca_city IN (SELECT ca_city FROM customer_address WHERE ca_address_sk = ai.ca_address_sk)
    LEFT JOIN (
        SELECT 
            cd_gender,
            (COUNT(*)::decimal / SUM(COUNT(*)) OVER ()) * 100 AS gender_percentage 
        FROM 
            customer_demographics 
        GROUP BY 
            cd_gender
    ) di_gender_percentage ON di.cd_gender = di_gender_percentage.cd_gender
    LEFT JOIN (
        SELECT 
            cd_marital_status,
            (COUNT(*)::decimal / SUM(COUNT(*)) OVER ()) * 100 AS marital_percentage 
        FROM 
            customer_demographics 
        GROUP BY 
            cd_marital_status
    ) di_marital_percentage ON di.cd_marital_status = di_marital_percentage.cd_marital_status
    LEFT JOIN (
        SELECT 
            cd_education_status,
            (COUNT(*)::decimal / SUM(COUNT(*)) OVER ()) * 100 AS education_percentage 
        FROM 
            customer_demographics 
        GROUP BY 
            cd_education_status
    ) di_education_percentage ON di.cd_education_status = di_education_percentage.cd_education_status
)
SELECT 
    DISTINCT full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    demographic_count,
    gender_percentage,
    marital_percentage,
    education_percentage 
FROM 
    CombinedInfo
ORDER BY 
    ca_city, cd_gender;
