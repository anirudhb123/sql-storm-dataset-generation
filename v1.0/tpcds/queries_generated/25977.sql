
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressCustomer AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating
    FROM 
        AddressDetails ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerInfo ci ON c.c_customer_sk = ci.c_customer_id
),
AggregatedResults AS (
    SELECT 
        ad.ca_state,
        COUNT(ad.c_customer_id) AS total_customers,
        AVG(ad.cd_purchase_estimate) AS avg_purchase_estimation,
        STRING_AGG(ad.full_address, ', ') AS address_list
    FROM 
        AddressCustomer ad
    GROUP BY 
        ad.ca_state
)
SELECT 
    ar.ca_state,
    ar.total_customers,
    ar.avg_purchase_estimation,
    ar.address_list
FROM 
    AggregatedResults ar
ORDER BY 
    ar.total_customers DESC;
