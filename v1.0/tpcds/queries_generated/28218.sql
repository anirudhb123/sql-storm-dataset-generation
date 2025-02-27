
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_country) AS country_lower,
        LENGTH(ca_zip) AS zip_length
    FROM 
        customer_address
),
filtered_customers AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate > 5000
),
aggregated_data AS (
    SELECT 
        pa.full_address,
        fc.full_name,
        fc.cd_gender,
        fc.cd_marital_status,
        COUNT(fc.c_customer_sk) AS customer_count
    FROM 
        processed_addresses pa
    JOIN 
        filtered_customers fc ON pa.ca_address_sk = fc.c_current_addr_sk
    GROUP BY 
        pa.full_address, fc.full_name, fc.cd_gender, fc.cd_marital_status
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    STRING_AGG(full_name, ', ') AS customer_names,
    customer_count
FROM 
    aggregated_data
GROUP BY 
    full_address, cd_gender, cd_marital_status
ORDER BY 
    customer_count DESC;
