
WITH customer_full_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        cfi.full_name,
        cfi.ca_city,
        cfi.ca_state,
        cfi.cd_gender,
        cfi.cd_marital_status,
        cfi.cd_purchase_estimate,
        si.total_spent,
        si.total_orders
    FROM 
        customer_full_info cfi
    LEFT JOIN 
        sales_info si ON cfi.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    combined_info
ORDER BY 
    total_spent DESC
LIMIT 100;
