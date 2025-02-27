
WITH Address_Analysis AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics_Analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS distinct_marital_status
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Final_Report AS (
    SELECT 
        A.ca_state,
        A.address_count,
        A.avg_street_length,
        A.max_street_length,
        A.min_street_length,
        A.unique_cities,
        D.cd_gender,
        D.demographic_count,
        D.avg_purchase_estimate,
        D.distinct_marital_status
    FROM 
        Address_Analysis A
    JOIN 
        Demographics_Analysis D ON A.ca_state IS NOT NULL
)
SELECT 
    ca_state,
    address_count,
    avg_street_length,
    max_street_length,
    min_street_length,
    unique_cities,
    cd_gender,
    demographic_count,
    avg_purchase_estimate,
    distinct_marital_status
FROM 
    Final_Report
ORDER BY 
    ca_state, cd_gender;
