
WITH String_Benchmark AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_country) AS lower_country,
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        REGEXP_REPLACE(ca_street_name, '[^A-Za-z ]', '') AS cleaned_street_name
    FROM 
        customer_address
), Demographics_Benchmark AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_education_status,
        cd_credit_rating,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_education_status, cd_credit_rating
)
SELECT 
    sb.ca_address_id,
    sb.street_name_length,
    sb.upper_city,
    sb.lower_country,
    sb.full_address,
    db.marital_statuses,
    db.demographic_count
FROM 
    String_Benchmark sb
JOIN 
    Demographics_Benchmark db ON sb.ca_address_id = db.cd_demo_sk 
WHERE 
    sb.street_name_length > 10
ORDER BY 
    sb.street_name_length DESC;
