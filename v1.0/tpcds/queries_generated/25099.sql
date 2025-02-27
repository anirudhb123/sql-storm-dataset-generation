
WITH AddressInfo AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
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
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ai.full_address,
    si.ws_order_number,
    si.total_quantity,
    si.total_sales
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_item_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M'
    AND si.total_sales > 100
ORDER BY 
    si.total_sales DESC;
