
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
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
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address,
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
        ws.ws_sales_price,
        ws.ws_ship_customer_sk,
        ws.ws_bill_customer_sk,
        w.w_warehouse_id,
        w.w_city AS warehouse_city
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
CombinedInfo AS (
    SELECT
        ci.customer_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        sd.full_address,
        si.ws_order_number,
        si.ws_sales_price,
        si.warehouse_city
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressDetails sd ON ci.c_customer_id = sd.ca_address_id
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT
    customer_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    full_address,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_sales_price) AS total_spent,
    warehouse_city
FROM 
    CombinedInfo
GROUP BY 
    customer_name, c_email_address, cd_gender, cd_marital_status, full_address, warehouse_city
ORDER BY 
    total_spent DESC
LIMIT 100;
