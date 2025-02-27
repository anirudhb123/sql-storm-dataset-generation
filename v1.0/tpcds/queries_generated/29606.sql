
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city, 
        ca.ca_state,
        ca.ca_zip,
        COALESCE(ca.ca_country, 'Unknown') AS country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
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
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    ci.cd_dep_count,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.country,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0.00) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    ci.cd_purchase_estimate DESC;
