
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_type || ' ' || ca_street_number, ', ') AS full_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicDetails AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            ELSE 'Female'
        END AS gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
JoinDetails AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.address_count,
        ad.full_address,
        dd.gender,
        dd.customer_count,
        dd.avg_purchase_estimate,
        dd.total_dependents
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dd ON ad.address_count > 10
)
SELECT
    city,
    state,
    address_count,
    full_address,
    gender,
    customer_count,
    avg_purchase_estimate,
    total_dependents
FROM 
    JoinDetails
ORDER BY 
    city, state;
