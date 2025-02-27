
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    a.full_address,
    s.total_sales,
    s.total_orders,
    COUNT(a.ca_address_sk) AS address_count,
    AVG(a.street_name_length) AS avg_street_name_length,
    AVG(a.city_length) AS avg_city_length,
    AVG(a.state_length) AS avg_state_length
FROM CustomerData c
JOIN AddressData a ON c.c_customer_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = c.c_customer_sk)
LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
GROUP BY c.full_name, c.cd_gender, c.cd_marital_status, c.cd_education_status, a.full_address, s.total_sales, s.total_orders
ORDER BY total_sales DESC
LIMIT 100;
