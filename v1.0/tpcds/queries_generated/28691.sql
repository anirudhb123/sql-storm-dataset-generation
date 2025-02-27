
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        COALESCE(NULLIF(cd.cd_marital_status, ''), 'Unknown') AS marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(CONCAT(c.c_first_name, '.', c.c_last_name, '@example.com')) AS normalized_email
    FROM 
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        ca.ca_city IS NOT NULL AND 
        ca.ca_state IS NOT NULL AND 
        cd.cd_gender IN ('M', 'F')
),
sales_data AS (
    SELECT 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN customer_info ci ON ws.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = ci.c_customer_id)
    GROUP BY ci.c_customer_id
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    si.total_quantity_sold,
    si.total_orders,
    si.total_revenue,
    CASE 
        WHEN si.total_revenue > 1000 THEN 'High Value'
        WHEN si.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    CASE 
        WHEN ci.marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status_category,
    CONCAT('Customer:', ci.full_name, ' | City: ', ci.ca_city, ' | State: ', ci.ca_state) AS customer_snapshot
FROM 
    customer_info ci
LEFT JOIN 
    sales_data si ON ci.c_customer_id = si.customer_id
ORDER BY 
    total_revenue DESC;
