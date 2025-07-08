
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        ARRAY_AGG(DISTINCT ca_city) AS cities,
        ARRAY_AGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type)) AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemoStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
JoinStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.cities,
        a.street_names,
        d.cd_gender AS gender,
        d.demographic_count,
        d.total_purchase_estimate
    FROM 
        AddressStats a
    JOIN 
        CustomerDemoStats d ON a.address_count > d.demographic_count
),
FinalOutput AS (
    SELECT 
        ca_state AS state,
        address_count,
        cities,
        street_names,
        gender,
        demographic_count,
        total_purchase_estimate,
        ROUND((total_purchase_estimate / NULLIF(demographic_count, 0)), 2) AS avg_purchase_per_demo
    FROM 
        JoinStats
    ORDER BY 
        address_count DESC
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    total_purchase_estimate > 10000;
