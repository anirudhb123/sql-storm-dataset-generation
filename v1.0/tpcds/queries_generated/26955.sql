
WITH AddressStats AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(wp.wp_char_count, 0)) AS total_char_count,
        AVG(LENGTH(ca.street_name)) AS avg_street_name_length
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY 
        ca.city, ca.state
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
FinalStats AS (
    SELECT 
        as.address_city,
        as.address_state,
        ds.cd_gender,
        ds.cd_marital_status,
        as.customer_count AS city_customer_count,
        ds.customer_count AS gender_marital_customer_count,
        as.total_char_count,
        as.avg_street_name_length,
        ds.total_dependents,
        ds.avg_purchase_estimate
    FROM 
        AddressStats as
    CROSS JOIN 
        DemographicStats ds
)
SELECT 
    address_city,
    address_state,
    cd_gender,
    cd_marital_status,
    city_customer_count,
    gender_marital_customer_count,
    total_char_count,
    avg_street_name_length,
    total_dependents,
    avg_purchase_estimate
FROM 
    FinalStats
ORDER BY 
    address_city, address_state, cd_gender, cd_marital_status;
