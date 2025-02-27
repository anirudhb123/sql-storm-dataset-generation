
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FullCustomerData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        si.total_sales,
        si.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressInfo ai ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = ci.c_customer_sk)
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_id)
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    ca_city,
    ca_state,
    total_sales,
    total_orders
FROM 
    FullCustomerData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC, full_name;
