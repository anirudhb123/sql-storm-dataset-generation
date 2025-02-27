
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        STRING_AGG(CASE WHEN ca_suite_number IS NOT NULL THEN ca_suite_number ELSE 'N/A' END, ', ') AS suite_numbers
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics 
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.address_count,
    ai.street_names,
    ai.suite_numbers,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_dependents,
    ds.employed_dependents,
    ds.education_statuses
FROM 
    AddressInfo ai
JOIN 
    DemographicSummary ds ON ai.ca_state = (SELECT TOP 1 ca_state FROM customer_address ORDER BY NEWID())
ORDER BY 
    ai.address_count DESC, ds.customer_count DESC;
