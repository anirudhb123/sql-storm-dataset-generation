
WITH AddressData AS (
    SELECT 
        ca_city,
        ca_state,
        UPPER(ca_street_name) AS uppercase_street_name,
        LENGTH(ca_street_name) AS street_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state,
        ad.uppercase_street_name,
        ad.street_length,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressData ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_order_number) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM 
        web_sales ws
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.marital_status,
    SUM(sd.total_order_value) AS total_spent,
    COUNT(sd.ws_order_number) AS total_orders,
    MAX(cd.street_length) AS max_street_length,
    ARRAY_AGG(DISTINCT cd.full_address ORDER BY cd.full_address) AS unique_addresses 
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_id = sd.ws_order_number
GROUP BY 
    cd.c_customer_id, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.marital_status
ORDER BY 
    total_spent DESC
LIMIT 10;
