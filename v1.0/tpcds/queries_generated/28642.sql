
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
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
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    si.total_sales,
    si.net_profit,
    si.last_purchase_date
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_id = ad.ca_address_id
JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_order_number
WHERE 
    si.total_sales > 1000
ORDER BY 
    si.total_sales DESC;
