
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
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
FormattedAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', 
               ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
ProminentCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        fa.full_address
    FROM 
        RankedCustomers rc
    JOIN 
        customer c ON rc.c_customer_id = c.c_customer_id
    JOIN 
        FormattedAddresses fa ON c.c_current_addr_sk = fa.ca_address_id
    WHERE 
        rc.rank <= 3
)
SELECT 
    pc.full_name,
    pc.cd_gender,
    pc.cd_marital_status,
    pc.cd_education_status,
    pc.cd_purchase_estimate,
    pc.full_address
FROM 
    ProminentCustomers pc
ORDER BY 
    pc.cd_gender, 
    pc.cd_purchase_estimate DESC;
