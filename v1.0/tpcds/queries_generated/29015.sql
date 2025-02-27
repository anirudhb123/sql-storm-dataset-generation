
WITH formatted_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS formatted_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        fa.formatted_address,
        fa.ca_city,
        fa.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        formatted_addresses fa ON c.c_current_addr_sk = fa.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    COUNT(DISTINCT(ws.ws_order_number)) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT cd.cd_marital_status) AS marital_statuses
FROM 
    customer_details cd
LEFT JOIN 
    web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cd.full_name, cd.ca_city, cd.ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
