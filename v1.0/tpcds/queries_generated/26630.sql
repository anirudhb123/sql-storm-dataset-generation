
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        UPPER(TRIM(ca_city)) AS city_upper,
        INITCAP(TRIM(ca_state)) AS state_capitalized,
        REGEXP_REPLACE(TRIM(ca_zip), '[^0-9]', '') AS cleaned_zip
    FROM 
        customer_address
), 
demographic_summary AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    p.city_upper,
    p.state_capitalized,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.max_dependent_count,
    LENGTH(p.full_address) AS address_length,
    CHAR_LENGTH(p.cleaned_zip) AS cleaned_zip_length
FROM 
    processed_addresses p
JOIN 
    demographic_summary d ON p.ca_address_sk = (SELECT MIN(ca_address_sk) FROM customer_address)
WHERE 
    d.customer_count > 100
ORDER BY 
    p.city_upper, d.avg_purchase_estimate DESC, address_length DESC;
