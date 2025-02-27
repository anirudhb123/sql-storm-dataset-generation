
WITH AddressInfo AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip 
    FROM 
        customer_address 
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        c_customer_id, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status 
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender IS NOT NULL
),
SalesInfo AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_zip,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    CustomerInfo ci
JOIN 
    customer_address ca ON ci.c_customer_id = ca.ca_address_id  -- Assuming customer_address has a mapping to customers
JOIN 
    AddressInfo ai ON ca.ca_address_id = ai.ca_address_id
LEFT JOIN 
    SalesInfo si ON ci.c_customer_sk = si.bill_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
ORDER BY 
    total_sales DESC 
LIMIT 10;
