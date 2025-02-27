
WITH string_benchmarks AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        REPLACE(ca_street_name, ' ', '-') AS street_name_hyphenated,
        SUBSTRING(ca_street_name, 1, 10) AS street_name_short
    FROM 
        customer_address
), aggregated_data AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_city) AS distinct_cities,
        AVG(street_name_length) AS avg_street_name_length,
        STRING_AGG(upper_street_name, ', ') AS upper_street_names,
        STRING_AGG(street_name_hyphenated, ', ') AS hyphenated_street_names
    FROM 
        string_benchmarks
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.distinct_cities,
    a.avg_street_name_length,
    a.upper_street_names,
    LENGTH(a.upper_street_names) AS total_upper_length,
    a.hyphenated_street_names,
    LEAST(a.avg_street_name_length, 50) AS capped_avg_length
FROM 
    aggregated_data a
ORDER BY 
    a.distinct_cities DESC, a.avg_street_name_length DESC;
