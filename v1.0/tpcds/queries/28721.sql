
WITH ranked_addresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        CHAR_LENGTH(ca_street_name) AS street_name_char_length,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        REPLACE(ca_street_name, 'Street', 'St') AS modified_street_name,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS rank
    FROM 
        customer_address
),
filtered_addresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        street_name_length,
        upper_street_name,
        modified_street_name
    FROM 
        ranked_addresses
    WHERE 
        rank <= 10
)
SELECT 
    f.ca_city,
    f.ca_state,
    COUNT(*) AS address_count,
    AVG(f.street_name_length) AS avg_street_name_length,
    STRING_AGG(f.upper_street_name, ', ') AS all_upper_street_names,
    STRING_AGG(f.modified_street_name, '; ') AS all_modified_street_names
FROM 
    filtered_addresses f
GROUP BY 
    f.ca_city, 
    f.ca_state
ORDER BY 
    address_count DESC;
