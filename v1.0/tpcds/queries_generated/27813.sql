
WITH AddressInfo AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ai.full_address,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status
    FROM
        web_sales ws
    JOIN AddressInfo ai ON ai.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ws.ws_bill_customer_sk)
    JOIN CustomerInfo ci ON ci.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    si.full_name,
    si.cd_gender,
    si.cd_marital_status,
    si.full_address,
    SUM(si.ws_quantity) AS total_quantity_sold,
    SUM(si.ws_net_profit) AS total_net_profit,
    COUNT(si.ws_order_number) AS total_orders
FROM 
    SalesInfo si
WHERE 
    si.cd_gender = 'F' AND
    (si.cd_marital_status = 'S' OR si.cd_marital_status = 'M')
GROUP BY 
    si.full_name, si.cd_gender, si.cd_marital_status, si.full_address
ORDER BY 
    total_net_profit DESC
LIMIT 10;
