
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
Result AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ad.full_address,
        sd.total_quantity,
        sd.total_net_paid
    FROM CustomerInfo ci
    JOIN AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_net_paid IS NULL THEN 'No Purchases'
        WHEN total_net_paid < 100 THEN 'Low Spender'
        WHEN total_net_paid BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM Result
ORDER BY total_net_paid DESC
LIMIT 50;
