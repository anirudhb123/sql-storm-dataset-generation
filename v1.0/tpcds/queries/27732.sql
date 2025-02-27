
WITH String_Benchmark AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LOWER(ca.ca_city) AS lower_city,
        UPPER(ca.ca_state) AS upper_state,
        LENGTH(ca.ca_zip) AS zip_length,
        REPLACE(ca.ca_street_name, ' ', '') AS street_name_no_spaces,
        TRIM(ca.ca_street_name) AS trimmed_street_name,
        SUBSTR(ca.ca_street_name, 1, 10) AS street_name_prefix
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('NY', 'CA', 'TX') 
    ORDER BY 
        ca.ca_address_id
),
Aggregated_Results AS (
    SELECT
        lower_city,
        upper_state,
        COUNT(*) AS address_count,
        AVG(zip_length) AS avg_zip_length,
        MAX(street_name_prefix) AS max_street_name_prefix
    FROM 
        String_Benchmark
    GROUP BY 
        lower_city, upper_state
)
SELECT 
    B.lower_city,
    B.upper_state,
    B.address_count,
    B.avg_zip_length,
    (B.avg_zip_length * 1.0) / NULLIF(B.address_count, 0) AS zip_length_per_address,
    STRING_AGG(B.max_street_name_prefix, ', ') AS max_street_names
FROM 
    Aggregated_Results B
GROUP BY 
    B.lower_city, 
    B.upper_state, 
    B.address_count,
    B.avg_zip_length
ORDER BY 
    B.lower_city, 
    B.upper_state;
