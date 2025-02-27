
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
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
        d.d_year = 2023
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    JOIN 
        date_info di ON ws.ws_ship_date_sk = di.d_date_sk
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    SUM(si.ws_sales_price) AS total_sales,
    COUNT(si.ws_order_number) AS order_count,
    SUM(si.ws_net_profit) AS total_profit
FROM 
    customer_info ci
JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
GROUP BY 
    ci.c_customer_id, ci.full_name, ci.ca_city, ci.ca_state
HAVING 
    SUM(si.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
