
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_birth_day,
        cd_birth_month,
        cd_birth_year,
        cd_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ws_bill_customer_sk
    FROM web_sales
),
DateInfo AS (
    SELECT 
        d_date_id, 
        d_date,
        d_month_seq, 
        d_year,
        d_week_seq
    FROM date_dim
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    si.ws_order_number,
    si.ws_sales_price,
    si.ws_ext_sales_price,
    di.d_date
FROM CustomerInfo ci
JOIN AddressInfo ai ON ci.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_addr_sk = ai.ca_address_sk)
JOIN SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
JOIN DateInfo di ON si.ws_sold_date_sk = di.d_date_sk
WHERE di.d_year = 2023
AND si.ws_sales_price > 100
ORDER BY di.d_date ASC, ci.full_name DESC
LIMIT 100;
