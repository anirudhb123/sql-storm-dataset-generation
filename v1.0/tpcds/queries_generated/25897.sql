
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        DEMO_DEMOGRAPHICS = (
            SELECT COUNT(*) 
            FROM household_demographics hd 
            WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
        ),
        ADDR_INFO = (
            SELECT full_street_address 
            FROM AddressParts 
            WHERE ca_address_sk = c.c_current_addr_sk
        )
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.full_name,
        ci.full_name || ' - ' || ci.c_email_address AS customer_info,
        ci.ADDR_INFO AS address_info
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    customer_info,
    AVG(ws_sales_price) AS average_sales_price,
    SUM(ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws_order_number) AS distinct_orders
FROM 
    SalesData
GROUP BY 
    customer_info
ORDER BY 
    average_sales_price DESC;
