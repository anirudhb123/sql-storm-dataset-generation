
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        SUM(CASE WHEN ca_zip LIKE '9%' THEN 1 ELSE 0 END) AS zip_starting_with_nine
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
combined_summary AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.cities,
        a.zip_starting_with_nine,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate,
        d.max_dependents
    FROM 
        address_summary a
    FULL JOIN 
        demographic_summary d ON 1=1  -- Cross join to combine all states with all gender demographics
)
SELECT 
    cs.ca_state,
    cs.unique_addresses,
    cs.cities,
    cs.zip_starting_with_nine,
    cs.cd_gender,
    cs.customer_count,
    COALESCE(cs.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    COALESCE(cs.max_dependents, 0) AS max_dependents,
    CASE 
        WHEN cs.zip_starting_with_nine > 0 THEN 'Contains zip starting with 9'
        ELSE 'No zip starting with 9'
    END AS zip_status
FROM 
    combined_summary cs
ORDER BY 
    cs.ca_state, cs.cd_gender;
