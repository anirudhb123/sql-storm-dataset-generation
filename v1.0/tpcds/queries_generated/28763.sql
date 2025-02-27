
WITH CustomerInfo AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUBSTRING(c.c_email_address FROM 1 FOR POSITION('@' IN c.c_email_address) - 1) AS email_prefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        COUNT(*) OVER() AS total_customers
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.full_name IS NOT NULL
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    ca_city,
    ca_state,
    total_customers,
    ROW_NUMBER() OVER (ORDER BY full_name) AS row_num
FROM 
    CombinedInfo
WHERE 
    cd_gender = 'F' 
    AND total_customers > 50
ORDER BY 
    full_name
LIMIT 100;
