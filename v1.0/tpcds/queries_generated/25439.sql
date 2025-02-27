
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        SUBSTRING_INDEX(c.c_login, '_', -1) AS login_suffix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_date AS sale_date,
        d.d_month_seq,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    SUM(si.ws_sales_price) AS total_spent,
    COUNT(si.ws_order_number) AS total_orders,
    MIN(si.sale_date) AS first_purchase_date,
    MAX(si.sale_date) AS last_purchase_date,
    COUNT(DISTINCT si.d_month_seq) AS months_active,
    ci.email_domain,
    ci.login_suffix
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.ca_city, ci.ca_state, ci.email_domain, ci.login_suffix
HAVING 
    total_spent > 1000
ORDER BY 
    total_spent DESC;
