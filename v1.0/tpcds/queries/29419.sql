
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_address_list,
        SUM(CASE WHEN ca_zip LIKE '9%' THEN 1 ELSE 0 END) AS zip_starting_with_9_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
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
    a.full_address_list,
    a.zip_starting_with_9_count,
    c.cd_gender,
    c.customer_count,
    c.max_purchase_estimate,
    c.avg_dep_count
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = c.cd_gender
ORDER BY 
    a.address_count DESC, 
    c.customer_count DESC;
