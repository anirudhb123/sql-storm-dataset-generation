
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM CustomerDetails cd
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.bill_customer_sk
WHERE cd.cd_purchase_estimate > 1000
ORDER BY total_sales DESC
LIMIT 100;
