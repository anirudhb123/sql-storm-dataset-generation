
WITH CTE_Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CTE_Purchase_Stats AS (
    SELECT 
        c.customer_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_paid) AS total_spent,
        AVG(ws.net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        CTE_Customer_Info c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.customer_id
)
SELECT 
    customer_id,
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent,
    avg_order_value,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CTE_Customer_Info c
LEFT JOIN 
    CTE_Purchase_Stats ps ON c.c_customer_id = ps.customer_id
ORDER BY 
    total_spent DESC, full_name;
