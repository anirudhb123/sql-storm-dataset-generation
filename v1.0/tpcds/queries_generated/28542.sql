
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Info AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)
SELECT 
    ci.full_name,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    si.web_site_id,
    si.total_net_profit,
    si.total_orders
FROM 
    Address_Info ai
JOIN 
    Customer_Info ci ON ai.ca_address_sk = ci.c_customer_sk
JOIN 
    Sales_Info si ON ci.c_customer_sk = si.web_site_id
WHERE 
    ci.cd_gender = 'M' AND 
    ci.cd_marital_status = 'S' AND 
    si.total_net_profit > 1000
ORDER BY 
    si.total_net_profit DESC;
