
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        COUNT(*) AS AddressCount
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_country
), CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        SUM(cd_dep_count) AS TotalDependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
), JoinedData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        cs.AvgPurchaseEstimate,
        cs.TotalDependents
    FROM 
        customer c
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerStats cs ON c.c_current_cdemo_sk = cs.cd_demo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    CONCAT_WS(', ', c.c_first_name, c.c_last_name) AS CustomerNames,
    COUNT(*) AS CustomerCount,
    AVG(cs.AvgPurchaseEstimate) AS AvgPurchase,
    SUM(cs.TotalDependents) AS TotalDependents
FROM 
    AddressDetails ca
JOIN 
    JoinedData c ON ca.ca_city = c.ca_city AND ca.ca_state = c.ca_state AND ca.ca_country = c.ca_country
GROUP BY 
    ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY 
    CustomerCount DESC, ca.ca_city;
