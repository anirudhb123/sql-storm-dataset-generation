
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_city, 'City', 'Metro') AS modified_city,
        UPPER(ca_state) AS upper_state,
        ca_zip
    FROM 
        customer_address
),
combined_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.full_address,
        ca.modified_city,
        ca.upper_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        processed_addresses ca
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk LIMIT 1)
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS address_count,
    STRING_AGG(cd.cd_credit_rating, ', ') AS credit_ratings,
    STRING_AGG(DISTINCT ca.full_address, '; ') AS unique_addresses
FROM 
    combined_data cd
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MIN(d.d_date_sk) FROM date_dim)
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    address_count DESC
LIMIT 10;
