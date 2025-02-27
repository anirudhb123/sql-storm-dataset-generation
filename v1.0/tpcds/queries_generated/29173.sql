
WITH AddressData AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    LEFT JOIN 
        AddressData ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    cd.cd_marital_status,
    cd.cd_gender,
    LENGTH(ad.full_address) AS full_address_length,
    (SELECT COUNT(*) 
     FROM store 
     WHERE s_city = ad.ca_city 
     AND s_state = ad.ca_state) AS store_count_in_city,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders
FROM 
    CustomerDetails c
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    AddressData ad ON c.c_current_addr_sk = ad.ca_address_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > 5000
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, 
    ad.full_address, ad.ca_city, ad.ca_state, cd.cd_marital_status, cd.cd_gender
ORDER BY 
    full_name;
