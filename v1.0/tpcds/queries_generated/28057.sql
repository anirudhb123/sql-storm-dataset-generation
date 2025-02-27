
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ci.cd_dep_employed_count,
        ci.cd_dep_college_count,
        sd.total_sales,
        sd.order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ca.full_address,
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_sales,
    cs.order_count
FROM AddressInfo ca
JOIN CustomerSales cs ON ca.ca_address_sk = cs.ca_address_sk
WHERE ca.ca_city = 'Los Angeles'
AND cs.total_sales > 1000
ORDER BY cs.total_sales DESC;
