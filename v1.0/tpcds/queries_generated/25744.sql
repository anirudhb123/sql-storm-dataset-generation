
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopSpenders AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerDetails cd
    WHERE 
        cd.rank <= 10
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerAddress AS (
    SELECT 
        ts.full_name,
        ts.cd_gender,
        ts.cd_marital_status,
        ts.cd_education_status,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip
    FROM 
        TopSpenders ts
    JOIN 
        AddressInfo ai ON ts.c_customer_id = c.c_customer_id
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
FROM 
    CustomerAddress
ORDER BY 
    cd_gender, full_name;
