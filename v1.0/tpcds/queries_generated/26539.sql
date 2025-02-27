
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY', 'TX')
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate,
        cd_dep_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.cd_purchase_estimate,
    ad.full_address,
    ROUND(sd.total_sales, 2) AS total_sales_last_30_days,
    sd.order_count,
    ad.street_name_length
FROM CustomerInfo ci
JOIN AddressDetails ad ON ci.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ad.ca_address_sk)
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY total_sales_last_30_days DESC, ci.full_name;
