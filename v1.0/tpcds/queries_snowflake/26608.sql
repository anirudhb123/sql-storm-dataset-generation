
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_street_name) DESC) AS rn
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
),
MaxLengthAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state
    FROM 
        RankedAddresses
    WHERE 
        rn = 1
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        addr.ca_street_name,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
)
SELECT 
    COUNT(*) AS TotalCustomers,
    cd.ca_state,
    LISTAGG(CONCAT(cd.c_first_name, ' ', cd.c_last_name, ' (', cd.ca_street_name, ')'), ', ') AS CustomerList
FROM 
    CustomerDetails cd
JOIN 
    MaxLengthAddresses addr ON cd.ca_street_name = addr.ca_street_name 
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.ca_street_name, cd.ca_city, cd.ca_state
ORDER BY 
    TotalCustomers DESC;
