
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicAnalysis AS (
    SELECT 
        cd_demo_sk,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
),
CombinedData AS (
    SELECT 
        ca.ca_address_sk,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        da.female_count,
        da.male_count,
        da.average_purchase_estimate
    FROM 
        AddressComponents ac
    JOIN 
        customer c ON ac.ca_address_sk = c.c_current_addr_sk
    JOIN 
        DemographicAnalysis da ON c.c_current_cdemo_sk = da.cd_demo_sk
)
SELECT 
    CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS complete_address,
    female_count,
    male_count,
    average_purchase_estimate
FROM 
    CombinedData
WHERE 
    average_purchase_estimate > 5000
ORDER BY 
    ca_city, full_address;
