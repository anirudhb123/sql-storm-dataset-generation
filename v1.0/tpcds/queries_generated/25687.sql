
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca.ca_suite_number), '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ss.total_sales,
    ss.order_count,
    ss.avg_profit
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_id = ai.ca_address_id
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND ci.cd_marital_status = 'M'
ORDER BY 
    ss.total_sales DESC
LIMIT 50;
