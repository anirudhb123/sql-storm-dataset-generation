
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address AS ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.education_level,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        CONCAT(cd.cd_gender, '|', cd.cd_marital_status, '|', cd.cd_education_status) AS demographics_representation
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
AggregateResults AS (
    SELECT 
        cad.full_address,
        COUNT(*) AS count_customers,
        STRING_AGG(DISTINCT cd.demographics_representation, '; ') AS unique_demographics
    FROM 
        CustomerAddressDetails AS cad
    JOIN 
        customer AS c ON cad.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cad.full_address
)
SELECT 
    full_address,
    count_customers,
    unique_demographics
FROM 
    AggregateResults
WHERE 
    count_customers > 5
ORDER BY 
    count_customers DESC, full_address;
