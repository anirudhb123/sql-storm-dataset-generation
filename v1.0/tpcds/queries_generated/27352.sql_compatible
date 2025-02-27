
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        TRIM(UPPER(ca_street_name)) AS normalized_street_name,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
address_metrics AS (
    SELECT 
        ca_address_sk,
        LENGTH(normalized_street_name) AS street_name_length,
        LENGTH(full_address) AS complete_address_length,
        REGEXP_REPLACE(normalized_street_name, '[^A-Z]', '') AS street_name_alpha_only,
        CHAR_LENGTH(full_address) - CHAR_LENGTH(REPLACE(full_address, ' ', '')) AS space_count
    FROM 
        processed_addresses
),
demographics_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(ca_address_sk) AS address_count,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY 
        cd_demo_sk, cd_gender
),
final_benchmark AS (
    SELECT 
        am.ca_address_sk,
        am.street_name_length,
        am.complete_address_length,
        dm.cd_gender,
        dm.avg_purchase_estimate,
        am.space_count
    FROM 
        address_metrics am
    JOIN 
        demographics_summary dm ON am.ca_address_sk = dm.cd_demo_sk
)
SELECT 
    cd_gender,
    COUNT(*) AS address_record_count,
    AVG(street_name_length) AS avg_street_name_length,
    AVG(complete_address_length) AS avg_complete_address_length,
    SUM(space_count) AS total_spaces_in_addresses
FROM 
    final_benchmark
GROUP BY 
    cd_gender
ORDER BY 
    cd_gender;
