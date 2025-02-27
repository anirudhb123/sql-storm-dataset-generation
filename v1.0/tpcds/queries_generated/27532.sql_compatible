
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM 
        customer_address
), 
DemoCounts AS (
    SELECT 
        cd_demo_sk,
        COUNT(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM 
        customer_demographics 
    GROUP BY 
        cd_demo_sk
),
CombinedData AS (
    SELECT 
        ca.ca_address_sk,
        dp.cd_demo_sk,
        dp.total_dependents,
        dp.employed_dependents,
        dp.college_dependents,
        ap.full_address
    FROM 
        AddressParts ap
    LEFT JOIN 
        CombinedCustomerAddresses ca ON ca.current_addr_sk = ap.ca_address_sk
    LEFT JOIN 
        DemoCounts dp ON dp.cd_demo_sk = ca.current_cdemo_sk
)
SELECT 
    full_address, 
    COUNT(*) AS address_count,
    AVG(total_dependents) AS avg_dependents,
    AVG(employed_dependents) AS avg_employed_dependents,
    AVG(college_dependents) AS avg_college_dependents
FROM 
    CombinedData
GROUP BY 
    full_address
HAVING 
    COUNT(*) > 1
ORDER BY 
    avg_dependents DESC;
