
WITH Address AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Customer AS (
    SELECT 
        c_customer_id, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        ca_address_id
    FROM customer
    JOIN customer_demographics ON c_customer_sk = cd_demo_sk
),
Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders
FROM Customer c
JOIN Address a ON c.ca_address_id = a.ca_address_id
LEFT JOIN Sales s ON c.c_customer_id = s.ws_bill_customer_sk
WHERE a.ca_state = 'CA' 
  AND c.cd_marital_status = 'M'
ORDER BY total_sales DESC, full_name ASC
LIMIT 100;
