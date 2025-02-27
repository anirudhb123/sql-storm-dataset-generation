
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    gender,
    marital_status,
    COUNT(*) AS customer_count,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name, ' - ', full_address), '; ') AS customer_names
FROM 
    CustomerAnalysis
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    gender, marital_status;
