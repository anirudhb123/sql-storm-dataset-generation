
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca.ca_suite_number) END,
               ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    COALESCE(si.total_profit, 0) AS total_profit,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
    AND ci.cd_gender = 'F'
    AND si.total_profit > 1000
ORDER BY 
    ci.full_name;
