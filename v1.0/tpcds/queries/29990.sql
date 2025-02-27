
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT full_name) AS unique_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        CustomerAddressDetails
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_customers,
    a.avg_purchase_estimate,
    a.max_purchase_estimate,
    a.min_purchase_estimate,
    ROUND(AVG(LENGTH(cad.full_name)), 2) AS avg_name_length,
    STRING_AGG(DISTINCT cad.ca_city, ', ') AS associated_cities
FROM 
    AddressStatistics a
JOIN 
    CustomerAddressDetails cad ON a.ca_state = cad.ca_state
GROUP BY 
    a.ca_state, a.total_addresses, a.unique_customers, a.avg_purchase_estimate, a.max_purchase_estimate, a.min_purchase_estimate
ORDER BY 
    a.total_addresses DESC;
