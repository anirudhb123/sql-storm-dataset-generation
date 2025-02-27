
WITH AddressData AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
), 
CustomerData AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.web_site_id, ws.web_name
) 
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    s.total_orders,
    s.total_sales,
    s.total_discount
FROM AddressData a
JOIN CustomerData c ON a.ca_address_id = c.c_customer_id
JOIN SalesData s ON c.c_customer_id = s.web_site_id
WHERE c.cd_purchase_estimate > 1000
ORDER BY s.total_sales DESC, a.ca_city, c.full_name;
