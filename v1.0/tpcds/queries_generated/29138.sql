
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        CONCAT(ca_state, ' ', ca_zip) AS state_zip
    FROM customer_address
), 
CustomerInfo AS (
    SELECT
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk, 
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
FinalMetrics AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.city,
        ai.state_zip,
        sd.total_profit,
        sd.total_orders,
        CASE 
            WHEN ci.cd_purchase_estimate > 50000 THEN 'High Value'
            WHEN ci.cd_purchase_estimate BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM CustomerInfo ci
    JOIN AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.bill_customer_sk
)
SELECT 
    customer_value,
    COUNT(*) AS customer_count,
    AVG(total_profit) AS avg_profit,
    SUM(total_orders) AS total_orders,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM FinalMetrics
GROUP BY customer_value
ORDER BY customer_value DESC;
