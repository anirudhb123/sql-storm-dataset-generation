
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LOWER(ca_country) AS country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(COALESCE(cd.cd_gender, ''), COALESCE(cd.cd_marital_status, '')) AS gender_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
)
SELECT 
    ci.full_name,
    ci.gender_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    SUM(si.ws_sales_price) AS total_sales,
    SUM(si.ws_net_paid) AS total_paid
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_id = ad.ca_address_id
JOIN 
    SalesInfo si ON si.ws_order_number IN (
        SELECT DISTINCT ws_order_number
        FROM web_sales
        WHERE ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer)
    )
GROUP BY 
    ci.full_name, ci.gender_marital_status, ci.cd_education_status, 
    ci.cd_purchase_estimate, ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip
HAVING 
    SUM(si.ws_sales_price) > 1000
ORDER BY 
    total_paid DESC, total_sales DESC;
