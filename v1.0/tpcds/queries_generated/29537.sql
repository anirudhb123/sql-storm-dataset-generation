
WITH RelevantAddresses AS (
    SELECT 
        ca_address_id,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ' ', ca_state, ' ', ca_zip, ' ', ca_country)) AS full_address
    FROM 
        customer_address
),
HousingDemographics AS (
    SELECT 
        hd_demo_sk,
        ib_income_band_sk,
        hd_buy_potential,
        STRING_AGG(LOWER(CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status)), ', ') AS demographics
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        hd_demo_sk, ib_income_band_sk, hd_buy_potential
),
CombinedData AS (
    SELECT 
        ra.ca_address_id,
        ra.full_address,
        hd.ib_income_band_sk,
        hd.hd_buy_potential,
        hd.demographics
    FROM 
        RelevantAddresses ra
    JOIN 
        HousingDemographics hd ON NULLIF(ra.ca_zip, '') IS NOT NULL
)
SELECT 
    full_address,
    COUNT(*) AS address_count,
    STRING_AGG(demographics, '; ') AS aggregated_demographics
FROM 
    CombinedData
GROUP BY 
    full_address
HAVING 
    address_count > 1
ORDER BY 
    address_count DESC;
