
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        REPLACE(REPLACE(ca_zip, '-', ''), ' ', '') AS clean_zip
    FROM 
        customer_address 
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F') 
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        d.gender_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.full_address,
    si.total_sales,
    si.order_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    si.total_sales > 1000
ORDER BY 
    ci.c_last_name, ci.c_first_name;
