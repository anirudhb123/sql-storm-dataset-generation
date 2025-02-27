
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        si.total_sales,
        si.average_net_profit
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.c_customer_id = SUBSTRING(ai.ca_address_id, 1, CHAR_LENGTH(ci.c_customer_id))
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = SUBSTRING(si.ws_order_number, 1, CHAR_LENGTH(ci.c_customer_id))
)

SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    average_net_profit
FROM 
    CombinedInfo
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
