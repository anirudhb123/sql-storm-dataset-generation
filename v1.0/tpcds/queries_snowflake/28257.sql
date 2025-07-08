
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 10
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    hvc.full_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.cd_purchase_estimate,
    ad.ca_street_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip
FROM 
    HighValueCustomers hvc
JOIN 
    AddressDetails ad ON ad.ca_address_id IN 
        (SELECT c.c_customer_id FROM customer c WHERE hvc.full_name = CONCAT(c.c_first_name, ' ', c.c_last_name))
ORDER BY 
    hvc.cd_purchase_estimate DESC;
