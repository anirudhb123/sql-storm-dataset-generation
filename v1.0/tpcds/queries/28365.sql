
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name || ' ' || rc.c_last_name AS full_name,
        rc.cd_gender,
        rc.cd_education_status,
        ca.full_address
    FROM 
        RankedCustomers rc
    JOIN 
        CustomerAddresses ca ON rc.c_customer_sk = ca.ca_address_sk
)
SELECT 
    cd.cd_gender,
    COUNT(*) AS total_customers,
    STRING_AGG(ci.full_address, '; ') AS customer_addresses,
    STRING_AGG(ci.full_name, ', ') AS customer_names
FROM 
    CustomerInfo ci
JOIN 
    customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender
ORDER BY 
    total_customers DESC;
