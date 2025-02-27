
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        LOWER(ca.ca_street_name) AS street_name_lower,
        LENGTH(ca.ca_street_name) AS street_name_length,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
),
CustomerDemographicsEnhanced AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender_full,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
AddressAndDemographics AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        dem.gender_full,
        dem.purchase_estimate,
        dem.cd_marital_status
    FROM 
        CustomerAddressDetails ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographicsEnhanced dem ON dem.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    city,
    state,
    COUNT(*) AS total_customers,
    AVG(purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(first_name, ' ', last_name), ', ') AS customer_names
FROM 
    AddressAndDemographics
GROUP BY 
    city, state
HAVING 
    COUNT(*) > 10
ORDER BY 
    city, state;
