
WITH customer_data AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        customer_id, 
        total_quantity, 
        total_spent,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_data
)
SELECT 
    tc.customer_id, 
    tc.total_quantity, 
    tc.total_spent,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    COALESCE(ca.ca_country, 'Unknown') AS country
FROM 
    top_customers tc
LEFT JOIN 
    customer c ON c.c_customer_id = tc.customer_id
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_spent DESC;
