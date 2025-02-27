
WITH address_parts AS (
    SELECT 
        ca_address_id,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
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
usage_stats AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    u.total_orders,
    u.total_items_sold,
    u.total_revenue
FROM 
    address_parts a
JOIN 
    customer_info c ON a.ca_address_id = c.c_customer_id
LEFT JOIN 
    usage_stats u ON c.c_customer_id = u.web_site_id
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    u.total_revenue DESC
LIMIT 100;
