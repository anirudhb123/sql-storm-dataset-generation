
WITH AddressInfo AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length,
        LOWER(ca_country) AS country_lowercase
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id, 
        c_first_name || ' ' || c_last_name AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_net_paid_inc_tax,
        ws_net_profit,
        ws_ship_date_sk,
        ws_bill_customer_sk
    FROM 
        web_sales
)
SELECT 
    ai.full_address,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(si.ws_quantity) AS total_quantity,
    SUM(si.ws_net_paid_inc_tax) AS total_sales,
    AVG(si.ws_net_profit) AS average_profit,
    COUNT(DISTINCT si.ws_order_number) AS unique_orders,
    CASE 
        WHEN ai.country_lowercase = 'usa' THEN 'Domestic'
        ELSE 'International'
    END AS shipment_type
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.ca_address_id = ci.c_customer_id
JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
WHERE 
    ai.address_length > 20
GROUP BY 
    ai.full_address, ci.full_name, ci.cd_gender, ci.cd_marital_status, ai.country_lowercase
ORDER BY 
    total_sales DESC
LIMIT 100;
