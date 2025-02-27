
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.address_count,
        a.unique_addresses,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.address_count,
    ci.unique_addresses,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
FROM 
    CustomerInfo ci
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    ci.ca_city, ci.c_last_name;
