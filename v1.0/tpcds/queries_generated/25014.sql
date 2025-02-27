
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
Top10Customers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        RankedCustomers rc
    JOIN 
        AddressDetails ad ON rc.c_customer_id = c.c_customer_id
    WHERE 
        rc.gender_rank <= 10
)
SELECT 
    full_name,
    cd_gender,
    CONCAT(full_address, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS complete_address
FROM 
    Top10Customers
ORDER BY 
    cd_gender, full_name;
