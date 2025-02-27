
WITH RankedCustomer AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_purchase_estimate
    FROM 
        RankedCustomer r
    WHERE 
        r.rnk <= 10
),
AddressDetails AS (
    SELECT 
        c.c_customer_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        HighValueCustomers hv
    JOIN 
        customer_address ca ON hv.c_customer_id = ca.ca_address_id
)
SELECT 
    hv.c_customer_id,
    hv.c_first_name || ' ' || hv.c_last_name AS full_name,
    hv.cd_gender,
    hv.cd_marital_status,
    hv.cd_purchase_estimate,
    ad.ca_street_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip
FROM 
    HighValueCustomers hv
JOIN 
    AddressDetails ad ON hv.c_customer_id = ad.c_customer_id
ORDER BY 
    hv.cd_purchase_estimate DESC;
