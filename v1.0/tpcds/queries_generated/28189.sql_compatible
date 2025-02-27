
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
SalesDetails AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_ship_addr_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ad.full_address,
    sd.total_sales,
    sd.total_orders
FROM CustomerInfo ci
LEFT JOIN SalesDetails sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE ci.cd_purchase_estimate > 1000
ORDER BY sd.total_sales DESC
LIMIT 50;
