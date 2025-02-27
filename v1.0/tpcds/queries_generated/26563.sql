
WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
date_range AS (
    SELECT 
        d.d_date AS sale_date
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
    JOIN 
        date_range dr ON ws.ws_sold_date_sk = dr.sale_date
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    SUM(sd.ws_sales_price) AS total_spent,
    SUM(sd.ws_quantity) AS total_items,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders
FROM 
    customer_info ci
JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state
ORDER BY 
    total_spent DESC
LIMIT 10;
