
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesSummary AS (
    SELECT 
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        ws.bill_customer_sk
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
BenchmarkResults AS (
    SELECT 
        cd.full_name,
        cd.email_address,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ss.total_orders,
        ss.total_profit
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesSummary ss ON cd.c_customer_sk = ss.bill_customer_sk
)
SELECT 
    full_name,
    email_address,
    full_address,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS formatted_location,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_profit, 0.00) AS total_profit
FROM BenchmarkResults
WHERE total_profit > 0
ORDER BY total_orders DESC, total_profit DESC
LIMIT 100;
