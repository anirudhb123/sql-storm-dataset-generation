
WITH AddressLengths AS (
    SELECT 
        ca_address_sk,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length,
        CONCAT(ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS num_customers,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
StringManipulation AS (
    SELECT 
        ca.ca_address_sk,
        LENGTH(a.full_address) AS full_address_length,
        d.cd_gender,
        d.num_customers,
        d.avg_dependents,
        d.avg_purchase_estimate
    FROM 
        AddressLengths a
    JOIN 
        DemographicStats d ON d.num_customers IS NOT NULL
    JOIN 
        customer_address ca ON ca.ca_address_sk = a.ca_address_sk
)
SELECT 
    sm.sm_type,
    STRING_AGG(CONCAT('Address SK: ', ca.ca_address_sk, ', Full Address: ', a.full_address, ', Gender: ', d.cd_gender, 
              ', Avg Dependents: ', d.avg_dependents, ', Avg Purchase Estimate: ', d.avg_purchase_estimate), '; ') AS benchmark_address_info
FROM 
    StringManipulation sm
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    sm.sm_type;
