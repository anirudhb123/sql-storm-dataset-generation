
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicsData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
FullCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        dem.cd_gender,
        dem.cd_marital_status
    FROM 
        customer c
    JOIN 
        AddressData ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        DemographicsData dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
),
StringAggregation AS (
    SELECT 
        c_customer_sk,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS full_name,
        STRING_AGG(CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip), '; ') AS complete_address,
        MIN(cd_gender) AS gender,
        MIN(cd_marital_status) AS marital_status
    FROM 
        FullCustomerData
    GROUP BY 
        c_customer_sk
)
SELECT 
    c_customer_sk,
    full_name,
    complete_address,
    gender,
    marital_status
FROM 
    StringAggregation
WHERE 
    gender = 'M'
ORDER BY 
    full_name;
