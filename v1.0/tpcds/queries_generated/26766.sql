
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid 
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price, ws.ws_quantity, ws.ws_net_profit
),
FullCustomerDetails AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        cad.full_address,
        sd.ws_order_number,
        sd.total_net_paid,
        sd.ws_net_profit
    FROM 
        CustomerInfo ci
        LEFT JOIN CustomerAddressDetails cad ON ci.c_customer_id = cad.ca_address_id
        LEFT JOIN SalesData sd ON ci.c_customer_id = sd.ws_order_number
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    SUM(total_net_paid) AS total_spent,
    COUNT(ws_order_number) AS order_count,
    AVG(ws_net_profit) AS average_profit
FROM 
    FullCustomerDetails
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, full_address
ORDER BY 
    total_spent DESC
LIMIT 100;
