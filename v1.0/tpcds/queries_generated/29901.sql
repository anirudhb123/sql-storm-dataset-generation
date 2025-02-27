
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_level
    FROM 
        customer_demographics
)
SELECT 
    a.ca_address_id,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.purchase_level
FROM 
    AddressInfo a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    a.ca_city ILIKE '%ville%'
    AND d.cd_gender = 'F'
ORDER BY 
    a.ca_state, a.ca_city;
