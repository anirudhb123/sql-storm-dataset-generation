
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.city,
        ca.state,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.city, ca.state, cd.gender, cd.marital_status, cd.education_status, cd.purchase_estimate
),
sales_summary AS (
    SELECT 
        c.customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM 
        customer_info c
    JOIN 
        web_sales ws ON c.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        c.customer_id
)
SELECT 
    ci.customer_id,
    ci.full_name,
    ci.city,
    ci.state,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ci.purchase_estimate,
    ss.total_orders,
    ss.total_spent,
    ss.average_order_value,
    ci.promotions
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.customer_id = ss.customer_id
ORDER BY 
    ss.total_spent DESC NULLS LAST;
