
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate,
        ca_city,
        ca_state,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cd_purchase_estimate) OVER () AS median_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_stats AS (
    SELECT
        c.customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_spent
    FROM
        web_sales ws
    JOIN 
        customer_info c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ps.total_orders,
    ps.total_spent,
    ps.avg_spent,
    ci.ca_city,
    ci.ca_state,
    CASE 
        WHEN ps.avg_spent >= ci.median_purchase_estimate THEN 'Above Median'
        ELSE 'Below Median'
    END AS spending_behavior
FROM 
    customer_info ci
LEFT JOIN 
    purchase_stats ps ON ci.c_customer_sk = ps.customer_sk
ORDER BY 
    ps.total_spent DESC
LIMIT 100;
