WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(EXTRACT(YEAR FROM (cast('2002-10-01' as date) - c.c_birth_year))) AS age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        ca.ca_state IN ('NY', 'CA')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    customer_name,
    total_orders,
    total_spent,
    ROUND(total_spent / NULLIF(total_orders, 0), 2) AS average_spent_per_order,
    age
FROM 
    customer_data
WHERE 
    total_orders > 0
ORDER BY 
    total_spent DESC
LIMIT 100;