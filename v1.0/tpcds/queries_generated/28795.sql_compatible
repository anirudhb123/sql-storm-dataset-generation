
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LOWER(ca_country) AS country_lower
    FROM customer_address
),
processed_customers AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ENCRYPT(c_email_address) AS encrypted_email
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    pa.full_address,
    pc.full_name,
    pc.cd_gender,
    ss.total_net_profit,
    ss.order_count,
    pa.country_lower 
FROM processed_addresses pa
JOIN processed_customers pc ON pa.ca_address_sk = pc.c_customer_sk
JOIN sales_summary ss ON pc.c_customer_sk = ss.ws_bill_customer_sk
WHERE pa.ca_state = 'CA'
AND ss.total_net_profit > 1000
ORDER BY ss.total_net_profit DESC, pc.full_name ASC
LIMIT 50;
