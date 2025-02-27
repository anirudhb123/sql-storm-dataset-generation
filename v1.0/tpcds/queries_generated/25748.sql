
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        UPPER(ca_street_name) AS processed_street_name,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.processed_street_name,
        ca.full_address,
        ca.street_name_length,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.processed_street_name,
    ci.full_address,
    ci.street_name_length,
    ci.email_prefix,
    ss.total_orders,
    ss.total_revenue,
    ss.avg_profit
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.web_site_sk
WHERE 
    ci.street_name_length > 5
ORDER BY 
    ci.c_last_name, ci.c_first_name;
