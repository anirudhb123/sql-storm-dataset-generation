
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        c.c_email_address,
        c.c_login
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
order_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
joined_data AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        cd.full_address,
        cd.c_email_address,
        cd.c_login,
        os.order_count,
        os.total_spent,
        os.last_order_date
    FROM 
        customer_details cd
    LEFT JOIN 
        order_summary os ON cd.c_customer_id = os.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    full_address,
    c_email_address,
    c_login,
    order_count,
    total_spent,
    last_order_date,
    CASE 
        WHEN total_spent IS NULL THEN 'No Orders'
        WHEN total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    joined_data
WHERE 
    cd_gender = 'M'
ORDER BY 
    total_spent DESC
LIMIT 50;
