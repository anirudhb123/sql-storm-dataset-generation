
WITH AddressInfo AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL AND ca.ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', TRIM(ca.ca_suite_number) ) 
                    ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    si.total_orders,
    si.total_quantity,
    si.total_sales
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = ai.ca_address_sk LIMIT 1)
LEFT JOIN 
    SalesInfo si ON si.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ci.c_customer_sk)
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    si.total_sales DESC;
