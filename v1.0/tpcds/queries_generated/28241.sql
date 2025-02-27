
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
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
        cd_birth_country,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetail AS (
    SELECT 
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        d_year,
        d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    SUM(sd.ws_sales_price) AS total_sales,
    AVG(sd.ws_net_profit) AS average_profit,
    COUNT(sd.ws_order_number) AS total_orders,
    MIN(sd.d_month_seq) AS first_order_month,
    MAX(sd.d_month_seq) AS last_order_month
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
JOIN 
    SalesDetail sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, 
    ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, ad.ca_country
ORDER BY 
    total_sales DESC
LIMIT 100;
