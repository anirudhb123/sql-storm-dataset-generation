
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_month DESC, c.c_birth_day DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
enhanced_customers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rs.total_orders,
        rs.total_spent
    FROM 
        ranked_customers rc
    LEFT JOIN 
        recent_sales rs ON rc.c_customer_id = rs.ws_bill_customer_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    e.full_name,
    e.cd_gender,
    e.cd_marital_status,
    e.cd_education_status,
    COALESCE(e.total_orders, 0) AS total_orders,
    COALESCE(e.total_spent, 0.00) AS total_spent
FROM 
    enhanced_customers e
ORDER BY 
    e.total_spent DESC, e.full_name;
