
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        UPPER(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
date_info AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_day_name
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ai.full_address,
    ai.ca_zip,
    ai.ca_country,
    di.d_date,
    di.d_day_name,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    address_info ai ON ci.ca_address_id = ai.ca_address_id
LEFT JOIN 
    date_info di ON ws.ws_sold_date_sk = di.d_date_sk
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state, ci.cd_gender, ai.full_address, ai.ca_zip, ai.ca_country, di.d_date, di.d_day_name
ORDER BY 
    total_spent DESC
LIMIT 50;
