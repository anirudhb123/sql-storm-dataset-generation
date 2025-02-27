
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        TRIM(REGEXP_REPLACE(ca_street_name, '[^A-Za-z0-9 ]', '')) AS cleaned_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
AddressCount AS (
    SELECT 
        COUNT(*) AS address_count,
        ca_state
    FROM 
        AddressDetails
    GROUP BY 
        ca_state
),
StringBenchmark AS (
    SELECT 
        a.cleaned_street_name,
        d.cd_gender,
        d.cd_marital_status,
        a.full_address,
        ac.address_count
    FROM 
        AddressDetails a
    JOIN 
        CustomerDemographics d ON a.ca_address_id LIKE '%' || d.cd_gender || '%' 
    JOIN 
        AddressCount ac ON a.full_address LIKE '%' || ac.ca_state || '%'
    WHERE 
        LENGTH(a.cleaned_street_name) > 5
    ORDER BY 
        LENGTH(a.cleaned_street_name) DESC
)
SELECT 
    cleaned_street_name,
    cd_gender,
    cd_marital_status,
    full_address,
    address_count
FROM 
    StringBenchmark
LIMIT 100;
