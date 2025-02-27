
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zips,
        MAX(LENGTH(full_address)) AS max_address_length,
        AVG(LENGTH(full_address)) AS avg_address_length
    FROM 
        processed_addresses
    GROUP BY 
        ca_state
)
SELECT 
    as.ca_state,
    as.total_addresses,
    as.unique_cities,
    as.unique_zips,
    as.max_address_length,
    as.avg_address_length,
    cd.cd_gender,
    COUNT(cd.cd_demo_sk) AS demographic_count
FROM 
    address_summary as as
JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (
        SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk IN (
            SELECT ca_address_sk FROM customer_address WHERE ca_state = as.ca_state
        )
    )
GROUP BY 
    as.ca_state, cd.cd_gender
ORDER BY 
    as.ca_state, cd.cd_gender;
