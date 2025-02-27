
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY') 
),

CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_id
)

SELECT
    COUNT(*) AS total_customers,
    cd_gender,
    COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_customers,
    COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_customers,
    STRING_AGG(CONCAT_WS(', ', full_name, full_address), '; ') AS customer_details
FROM 
    CustomerInfo
GROUP BY 
    cd_gender
ORDER BY 
    total_customers DESC;
