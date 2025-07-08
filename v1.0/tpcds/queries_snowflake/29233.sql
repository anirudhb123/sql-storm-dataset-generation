
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
), Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics
), CombinedData AS (
    SELECT 
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.purchase_category,
        a.street_name_length
    FROM 
        AddressParts a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    purchase_category,
    COUNT(*) AS customer_count,
    AVG(street_name_length) AS avg_street_name_length,
    LISTAGG(full_address, '; ') AS sample_addresses
FROM 
    CombinedData
GROUP BY 
    purchase_category
ORDER BY 
    customer_count DESC;
