
WITH AddressFields AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS complete_address
    FROM 
        customer_address
),
CustomerFields AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesFields AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_sales_price,
        ws_ext_discount_amt
    FROM 
        web_sales
)
SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.ws_net_paid) AS total_net_paid,
    AVG(s.ws_sales_price) AS average_sales_price,
    SUM(s.ws_ext_discount_amt) AS total_discount
FROM 
    AddressFields a
JOIN 
    CustomerFields c ON a.ca_address_id = c.c_customer_id
JOIN 
    SalesFields s ON c.c_customer_id = s.ws_order_number
WHERE 
    a.ca_state = 'CA' 
GROUP BY 
    a.full_address, c.full_name, c.cd_gender, c.cd_marital_status
ORDER BY 
    total_net_paid DESC
LIMIT 100;
