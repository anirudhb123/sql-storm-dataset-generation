
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN ca_street_name IS NOT NULL THEN 1 ELSE 0 END) AS street_name_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_city) AS unique_cities,
        STRING_AGG(DISTINCT ca_city, ', ') AS all_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_marital_status) AS marital_status_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.street_name_count,
    A.avg_street_name_length,
    A.unique_cities,
    A.all_cities,
    D.cd_gender,
    D.total_customers,
    D.avg_dependents,
    D.marital_status_list
FROM 
    AddressStatistics A
JOIN 
    DemographicsAnalysis D ON A.total_addresses > 50 AND D.total_customers > 100
ORDER BY 
    A.total_addresses DESC, 
    D.total_customers DESC;
