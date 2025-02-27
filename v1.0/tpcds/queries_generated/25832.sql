
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, COALESCE(CONCAT(' ', ca.ca_suite_number), '')) AS full_address,
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
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_date AS sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ad.full_address,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_net_profit) AS total_profit,
    MIN(sd.sale_date) AS first_purchase_date,
    MAX(sd.sale_date) AS last_purchase_date
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_address_id = ad.ca_address_id LIMIT 1))
LEFT JOIN 
    SalesData sd ON sd.ws_bill_customer_sk = ci.c_customer_sk
GROUP BY 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_purchase_estimate, 
    ad.full_address
ORDER BY 
    total_profit DESC;
