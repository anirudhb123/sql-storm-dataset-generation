
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
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
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        hc.full_name
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        HighValueCustomers hc ON c.c_customer_sk = hc.c_customer_sk
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    COUNT(*) AS customer_count,
    STRING_AGG(ad.full_name, ', ') AS customer_names
FROM 
    AddressDetails ad
GROUP BY 
    ad.ca_city, 
    ad.ca_state, 
    ad.ca_country
ORDER BY 
    customer_count DESC;
