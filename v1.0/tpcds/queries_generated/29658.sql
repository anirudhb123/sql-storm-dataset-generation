
WITH formatted_addresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS formatted_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        cd.cd_purchase_estimate
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_distribution AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.full_name,
    a.formatted_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    s.total_sales,
    d.address_count
FROM customer_details c
JOIN formatted_addresses a ON c.c_customer_sk = a.ca_address_sk
JOIN sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN address_distribution d ON a.ca_state = d.ca_state
WHERE c.cd_gender = 'M'
AND s.total_sales > 1000
ORDER BY c.full_name, d.address_count DESC;
