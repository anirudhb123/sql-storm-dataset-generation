
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_result AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ai.full_address,
        COALESCE(ss.total_spent, 0) AS total_spent,
        COALESCE(ss.orders_count, 0) AS orders_count
    FROM 
        customer_info ci
    JOIN 
        address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    c_first_name,
    c_last_name,
    c_email_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_spent,
    orders_count,
    full_address
FROM 
    final_result
WHERE 
    total_spent > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
