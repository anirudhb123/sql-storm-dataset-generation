
WITH address_stats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type), ', ') AS street_names,
        SUM(CASE 
                WHEN ca_street_number IS NOT NULL THEN 1 
                ELSE 0 
            END) AS valid_street_numbers,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimation,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_status_types
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.address_count,
    a.street_names,
    a.valid_street_numbers,
    a.max_street_name_length,
    g.cd_gender,
    g.demographic_count,
    g.avg_purchase_estimation,
    g.marital_status_types
FROM 
    address_stats a
JOIN 
    gender_stats g ON a.address_count > 10 
ORDER BY 
    a.address_count DESC, 
    g.demographic_count DESC;
