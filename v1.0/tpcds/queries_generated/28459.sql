
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),

CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),

SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),

FinalReport AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ai.full_address,
        ci.cd_gender,
        si.total_sales,
        si.total_orders
    FROM CustomerInfo ci
    JOIN AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
    LEFT JOIN SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)

SELECT 
    full_name,
    full_address,
    cd_gender,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders
FROM FinalReport
WHERE cd_gender = 'F'
ORDER BY total_sales DESC
LIMIT 100;
