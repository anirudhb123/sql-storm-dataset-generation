
WITH 
    AddressAnalysis AS (
        SELECT 
            ca_city,
            ca_state,
            COUNT(*) AS address_count,
            LISTAGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names,
            LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS street_types,
            AVG(ca_gmt_offset) AS avg_gmt_offset
        FROM 
            customer_address
        GROUP BY 
            ca_city, ca_state
    ),
    CustomerAnalysis AS (
        SELECT 
            cd_gender,
            COUNT(DISTINCT c_customer_id) AS customer_count,
            AVG(cd_purchase_estimate) AS average_purchase_estimate,
            SUM(cd_dep_count) AS total_dependents
        FROM 
            customer c
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY 
            cd_gender
    )
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.street_names,
    a.street_types,
    a.avg_gmt_offset,
    c.cd_gender,
    c.customer_count,
    c.average_purchase_estimate,
    c.total_dependents
FROM 
    AddressAnalysis a
JOIN 
    CustomerAnalysis c ON a.avg_gmt_offset > 0
ORDER BY 
    a.ca_state, a.ca_city, c.cd_gender;
