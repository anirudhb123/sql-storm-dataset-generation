
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        MIN(LENGTH(ca_street_name)) AS min_street_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_length,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, '; ') AS customer_names
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.max_street_length,
    a.min_street_length,
    a.avg_street_length,
    a.unique_streets,
    c.cd_gender,
    c.customer_count,
    c.total_dependencies,
    c.avg_purchase_estimate,
    c.customer_names
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = (CASE 
                                          WHEN c.cd_gender = 'M' THEN 'CA' 
                                          WHEN c.cd_gender = 'F' THEN 'NY' 
                                          ELSE 'TX' END)
ORDER BY 
    a.address_count DESC, 
    c.customer_count DESC
LIMIT 100;
