
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = ci.c_customer_id)
)
SELECT 
    ci.full_name,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_sales_price) AS total_sales,
    ci.ca_city,
    ci.ca_state,
    COUNT(DISTINCT sd.ws_order_number) AS order_count
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.full_name = sd.full_name
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state
HAVING 
    SUM(sd.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
