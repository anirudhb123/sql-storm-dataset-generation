
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca_address_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.ca_address_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ai.ca_state = 'CA' 
    AND ci.cd_gender = 'F' 
    AND ci.cd_purchase_estimate > 500
ORDER BY 
    total_sales DESC, 
    ci.full_name;
