
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_ship_mode_sk,
        ws_bill_customer_sk
    FROM 
        web_sales
    WHERE 
        ws_quantity > 0
),
ShippingInfo AS (
    SELECT 
        sm.ship_mode_id,
        sm.sm_type
    FROM 
        ship_mode sm
)
SELECT 
    ci.full_name,
    ai.full_address,
    SUM(si.ws_quantity) AS total_quantity,
    SUM(si.ws_ext_sales_price) AS total_sales,
    si.ws_ship_mode_sk,
    si.ws_bill_customer_sk
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.ca_address_id = ci.c_customer_id
JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
JOIN 
    ShippingInfo shi ON si.ws_ship_mode_sk = shi.ship_mode_id
GROUP BY 
    ci.full_name, ai.full_address, si.ws_ship_mode_sk, si.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
