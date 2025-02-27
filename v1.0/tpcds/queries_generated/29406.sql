
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_order_date,
        d.d_month AS order_month,
        d.d_year AS order_year
    FROM 
        customer c
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status, ' - ', cd.cd_education_status) AS demographic_profile
    FROM 
        customer_demographics cd
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ad.full_address,
    ci.first_order_date,
    ci.order_month,
    ci.order_year,
    cd.demographic_profile,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    SUM(ws.ws_sales_price) AS total_sales_amount
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressDetails ad ON ci.c_customer_id = ad.ca_address_id
LEFT JOIN 
    web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON ci.c_customer_id = cd.cd_demo_sk
GROUP BY 
    ci.c_customer_id, 
    ci.full_name, 
    ad.full_address, 
    ci.first_order_date, 
    ci.order_month, 
    ci.order_year,
    cd.demographic_profile
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
