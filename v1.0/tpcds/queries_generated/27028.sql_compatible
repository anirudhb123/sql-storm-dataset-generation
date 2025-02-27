
WITH AddressDetails AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city, 
        ca_state, 
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        si.total_sales,
        si.order_count
    FROM 
        CustomerInfo ci
        JOIN AddressDetails ad ON ci.c_customer_id = ad.ca_address_id
        JOIN SalesInfo si ON si.ws_bill_customer_sk = ci.c_customer_id
)
SELECT 
    full_name, 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    CombinedInfo
WHERE 
    cd_gender = 'F' 
ORDER BY 
    total_sales DESC
LIMIT 50;
