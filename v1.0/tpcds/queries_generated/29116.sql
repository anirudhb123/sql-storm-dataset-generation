
WITH CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address, 
        LOWER(ca.ca_city) AS city_lower,
        UPPER(ca.ca_state) AS state_upper
    FROM 
        customer_address ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        ci.full_address,
        ci.city_lower,
        ci.state_upper,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        CustomerAddressInfo ci ON c.c_current_addr_sk = ci.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    STRING_AGG(DISTINCT ci.city_lower, ', ') AS unique_cities,
    MAX(ci.state_upper) AS max_state,
    MIN(ci.state_upper) AS min_state,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 10000 THEN 'High Value Customer'
        WHEN SUM(ws.ws_sales_price) BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_segment
FROM 
    CustomerInfo ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.c_email_address
ORDER BY 
    total_sales DESC
LIMIT 100;
