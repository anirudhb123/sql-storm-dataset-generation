
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ci.full_address,
        di.cd_gender, 
        di.cd_marital_status, 
        di.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        AddressInfo ci ON c.c_current_addr_sk = ci.ca_address_sk
    JOIN 
        DemographicInfo di ON c.c_current_cdemo_sk = di.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    ci.customer_name,
    ci.location,
    ci.cd_gender,
    ci.cd_marital_status,
    si.total_sales,
    si.order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.web_site_sk
WHERE 
    ci.cd_purchase_estimate > 1000 AND
    ci.cd_gender = 'F'
ORDER BY 
    si.total_sales DESC
LIMIT 50;
