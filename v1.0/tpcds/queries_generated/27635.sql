
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        ca_address_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(ws_order_number) AS orders_count, 
        SUM(ws_net_paid) AS total_spent
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
    ai.ca_country, 
    COALESCE(si.orders_count, 0) AS orders_count, 
    COALESCE(si.total_spent, 0.00) AS total_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.ca_address_sk = ai.ca_address_sk
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'M' 
    AND ci.cd_marital_status = 'S'
    AND si.total_spent > 100
ORDER BY 
    total_spent DESC
LIMIT 50;
