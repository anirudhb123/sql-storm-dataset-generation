
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_buy_potential) AS avg_buy_potential,
        COUNT(cd_demo_sk) AS demo_count
    FROM 
        household_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
CombinedStats AS (
    SELECT 
        a.ca_city,
        a.address_count,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        d.cd_gender,
        d.cd_marital_status,
        d.avg_buy_potential,
        d.demo_count
    FROM 
        AddressStats a
    JOIN 
        DemographicStats d ON a.address_count = d.demo_count
)
SELECT 
    ca.ca_city,
    ca.address_count,
    ca.avg_street_name_length,
    ca.max_street_name_length,
    ca.min_street_name_length,
    dc.cd_gender,
    dc.avg_buy_potential
FROM 
    CombinedStats ca
JOIN 
    (SELECT cd_gender, AVG(cd_purchase_estimate) AS avg_purchase_estimate
     FROM customer_demographics
     GROUP BY cd_gender) dc ON ca.cd_gender = dc.cd_gender
WHERE 
    ca.address_count > 10
ORDER BY 
    ca.avg_street_name_length DESC, 
    dc.avg_purchase_estimate DESC;
