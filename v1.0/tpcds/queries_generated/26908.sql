
WITH processed_addresses AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        TRIM(ca_country) AS country_trimmed
    FROM 
        customer_address
),
gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dep_count,
        MIN(cd_dep_count) AS min_dep_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
address_demographics AS (
    SELECT 
        pa.ca_address_id,
        pa.full_address,
        gs.gender_count,
        gs.avg_purchase_estimate,
        gs.max_dep_count,
        gs.min_dep_count
    FROM 
        processed_addresses pa
    JOIN 
        customer c ON pa.ca_address_id = c.c_current_addr_sk
    LEFT JOIN 
        gender_stats gs ON c.c_current_cdemo_sk IS NOT NULL
)
SELECT 
    ad.full_address,
    ad.gender_count,
    ad.avg_purchase_estimate,
    ad.max_dep_count,
    ad.min_dep_count
FROM 
    address_demographics ad
WHERE 
    ad.city_lower LIKE 'a%'
ORDER BY 
    ad.gender_count DESC, ad.avg_purchase_estimate DESC
LIMIT 100;
