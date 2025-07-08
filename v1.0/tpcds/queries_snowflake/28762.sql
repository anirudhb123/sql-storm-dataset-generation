
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        LISTAGG(CONCAT(c_first_name, ' ', c_last_name), ', ' ORDER BY c_last_name) AS customer_names
    FROM 
        customer_address 
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city, ca_state
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        LISTAGG(cd_education_status, ', ' ORDER BY cd_education_status) AS education_levels
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
CombinedAnalysis AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.customer_count,
        a.customer_names,
        d.cd_gender,
        d.cd_marital_status,
        d.total_dependents,
        d.education_levels
    FROM 
        AddressAnalysis a
    LEFT JOIN 
        DemographicAnalysis d ON a.customer_count > 0
)
SELECT 
    ca_city,
    ca_state,
    customer_count,
    customer_names,
    cd_gender,
    cd_marital_status,
    total_dependents,
    education_levels
FROM 
    CombinedAnalysis
WHERE 
    customer_count > 10
ORDER BY 
    ca_state, ca_city;
