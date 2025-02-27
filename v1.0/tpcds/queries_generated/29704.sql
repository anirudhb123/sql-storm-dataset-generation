
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) 
                    ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_net_profit,
    sd.total_orders,
    cd.customer_value
FROM CustomerDetails cd
JOIN AddressDetails ad ON cd.c_customer_sk IN (
    SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cd.c_customer_sk
)
LEFT JOIN SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE cd.cd_gender = 'F' AND cd.customer_value = 'High Value'
ORDER BY sd.total_net_profit DESC
LIMIT 10;
