
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
order_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
result AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        os.total_quantity,
        os.total_spent,
        os.total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        order_summary os ON ci.c_customer_id = os.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_spent = 0 THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Spender'
        WHEN total_spent < 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    result
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_spent DESC;
