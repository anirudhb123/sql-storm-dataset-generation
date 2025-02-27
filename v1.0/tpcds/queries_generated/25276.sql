
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', 
               ca_street_name, ' ', 
               ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        LOWER(ca_city) AS city_lowercase,
        UPPER(ca_state) AS state_uppercase,
        LEFT(ca_zip, 5) AS zip_prefix
    FROM 
        customer_address
),
AggregatedDemographics AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count,
        STRING_AGG(DISTINCT cd_marital_status) AS marital_statuses,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
AddressDemographicJoin AS (
    SELECT 
        pa.full_address,
        ad.cd_gender,
        ad.demographic_count,
        ad.marital_statuses,
        ad.avg_purchase_estimate
    FROM 
        ProcessedAddresses pa
    JOIN 
        customer c ON pa.ca_address_sk = c.c_current_addr_sk
    JOIN 
        AggregatedDemographics ad ON c.c_current_cdemo_sk IS NOT NULL
)
SELECT 
    a.full_address,
    a.city_lowercase,
    a.state_uppercase,
    a.zip_prefix,
    a.cd_gender,
    a.demographic_count,
    a.marital_statuses,
    a.avg_purchase_estimate,
    CHAR_LENGTH(a.full_address) AS address_length, 
    CHAR_LENGTH(a.marital_statuses) AS marital_status_length
FROM 
    AddressDemographicJoin a
WHERE 
    a.demo_count > 10 
ORDER BY 
    a.avg_purchase_estimate DESC, 
    a.state_uppercase ASC;
