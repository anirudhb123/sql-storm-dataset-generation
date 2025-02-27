
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        TRIM(ca_street_number) AS street_number,
        TRIM(ca_street_name) AS street_name,
        TRIM(ca_street_type) AS street_type,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
StreetAddressAnalysis AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        AVG(LENGTH(full_address)) AS avg_address_length,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length,
        STRING_AGG(DISTINCT street_type, ', ') AS distinct_street_types
    FROM 
        AddressParts
    GROUP BY 
        ca_state, 
        ca_city
),
ProcessedAddresses AS (
    SELECT 
        ca_state,
        ca_city,
        address_count,
        avg_address_length,
        max_address_length,
        min_address_length,
        distinct_street_types,
        CASE 
            WHEN address_count > 100 THEN 'High Volume'
            WHEN address_count BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM 
        StreetAddressAnalysis
)
SELECT 
    *,
    CONCAT('The number of addresses in ', ca_city, ', ', ca_state, ' is categorized as: ', volume_category) AS volume_description
FROM 
    ProcessedAddresses
ORDER BY 
    ca_state, 
    ca_city;
