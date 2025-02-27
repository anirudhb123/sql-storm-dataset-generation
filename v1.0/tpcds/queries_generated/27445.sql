
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS purchase_rank
    FROM 
        customer c
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
CustomerDemographics AS (
    SELECT 
        rc.c_customer_id,
        rc.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    JOIN 
        customer_demographics cd ON rc.c_customer_id = cd.cd_demo_sk
    WHERE 
        rc.purchase_rank = 1
),
AddressDetails AS (
    SELECT 
        cd.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        CustomerDemographics cd
    JOIN 
        customer_address ca ON cd.c_customer_id = ca.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM 
    CustomerDemographics cd
JOIN 
    AddressDetails ad ON cd.c_customer_id = ad.c_customer_id
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.cd_purchase_estimate DESC;
