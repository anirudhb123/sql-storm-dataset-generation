
WITH Address_Processing AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                   ELSE '' 
               END) AS full_address,
        UPPER(ca_city) AS city_uppercase,
        LOWER(ca_state) AS state_lowercase,
        REPLACE(ca_zip, '-', '') AS sanitized_zip
    FROM 
        customer_address
),
Demo_Statistics AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Date_Statistics AS (
    SELECT 
        d_year,
        COUNT(d_date_sk) AS day_count,
        STRING_AGG(DISTINCT d_day_name, ', ') AS weekdays_names
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    A.full_address,
    A.city_uppercase,
    A.state_lowercase,
    A.sanitized_zip,
    D.demo_count,
    D.avg_purchase_estimate,
    D.marital_statuses,
    Y.day_count,
    Y.weekdays_names
FROM 
    Address_Processing A
JOIN 
    (SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
     FROM 
        customer_demographics
     WHERE 
        cd_purchase_estimate > 0
     GROUP BY 
        cd_gender) D ON A.ca_address_sk = D.cd_demo_sk 
JOIN 
    Date_Statistics Y ON D.demo_count > Y.day_count
ORDER BY 
    A.full_address, D.demo_count DESC;
