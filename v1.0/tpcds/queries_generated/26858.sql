
WITH AddressProcessing AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix,
        UPPER(ca_city) AS upper_case_city,
        LOWER(ca_country) AS lower_case_country,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
),
CustomerProcessing AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_full,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalResults AS (
    SELECT 
        ap.full_address,
        ap.zip_prefix,
        ap.upper_case_city,
        cp.full_name,
        cp.gender_full,
        cp.cd_purchase_estimate
    FROM 
        AddressProcessing ap
    JOIN 
        CustomerProcessing cp ON cp.c_customer_sk % 100 = ap.ca_address_sk % 100  -- Simulating some join condition
)
SELECT 
    full_address,
    zip_prefix,
    upper_case_city,
    full_name,
    gender_full,
    cd_purchase_estimate,
    COUNT(*) OVER (PARTITION BY zip_prefix ORDER BY full_address) AS address_count
FROM 
    FinalResults
WHERE 
    LENGTH(full_address) > 20
ORDER BY 
    upper_case_city, address_count DESC;
