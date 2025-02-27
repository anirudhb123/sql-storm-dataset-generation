
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    AND 
        cd.cd_buy_potential = 'High'
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_zip,
        w.w_warehouse_name
    FROM 
        customer_address ca
    JOIN 
        warehouse w ON ca.ca_address_sk = w.w_warehouse_sk
    WHERE 
        ca.ca_state = 'CA'
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_zip,
    COUNT(*) OVER () AS total_customers
FROM 
    RankedCustomers rc
JOIN 
    AddressDetails ad ON rc.c_customer_id = ad.ca_address_id
WHERE 
    rc.rn <= 10
ORDER BY 
    rc.cd_gender, rc.full_name;
