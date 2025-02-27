
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
), FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.c_email_address,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn <= 5
), CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        fc.*
    FROM 
        customer_address ca
    JOIN 
        FilteredCustomers fc ON ca.ca_address_sk = fc.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(*) AS customer_count,
    STRING_AGG(CONCAT(fc.c_first_name, ' ', fc.c_last_name), ', ') AS customer_names
FROM 
    CustomerAddresses ca
JOIN 
    FilteredCustomers fc ON ca.c_customer_sk = fc.c_customer_sk
GROUP BY 
    ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY 
    customer_count DESC
LIMIT 10;
