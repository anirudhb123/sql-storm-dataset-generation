
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
AddressCounts AS (
    SELECT 
        a.ca_state,
        COUNT(*) AS address_count,
        LISTAGG(a.full_address, '; ') WITHIN GROUP (ORDER BY a.full_address) AS address_list
    FROM 
        AddressParts a
    GROUP BY 
        a.ca_state
),
CustomerAggregates AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_count) AS average_dependencies
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.address_list,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.total_purchase_estimate,
    ca.average_dependencies
FROM 
    AddressCounts ac
JOIN 
    CustomerAggregates ca ON ac.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT MIN(ca_address_sk) FROM customer_address))
ORDER BY 
    ac.address_count DESC, 
    ca.total_purchase_estimate DESC;
