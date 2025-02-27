
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
address_info AS (
    SELECT 
        ca.ca_address_id, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_address_id ORDER BY ca.ca_address_sk) AS rn
    FROM 
        customer_address ca
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)

SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders
FROM 
    customer_info ci
JOIN 
    address_info ai ON ci.c_customer_id = ai.ca_address_id AND ai.rn = 1
LEFT JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
WHERE 
    ci.rn = 1
ORDER BY 
    total_sales DESC, ci.full_name;
