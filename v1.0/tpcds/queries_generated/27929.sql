
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.city_state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_address_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_address_sk
)
SELECT 
    cd.customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    ss.total_sales,
    ss.order_count,
    cd.city_state_zip
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_address_sk
ORDER BY 
    total_sales DESC, customer_name;
