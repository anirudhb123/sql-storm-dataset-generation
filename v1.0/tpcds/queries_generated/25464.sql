
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', 
               COALESCE(ca_street_name, ''), ' ', 
               COALESCE(ca_street_type, ''), ' ', 
               COALESCE(ca_suite_number, ''), ', ', 
               COALESCE(ca_city, ''), ', ', 
               COALESCE(ca_state, ''), ' ', 
               COALESCE(ca_zip, ''), ', ', 
               COALESCE(ca_country, '')) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(COALESCE(c_first_name, ''), ' ', 
               COALESCE(c_last_name, '')) AS full_customer_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca_address_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ad.full_address,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressDetails ad ON cd.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.cd_purchase_estimate DESC;
