
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_day,
        cd.cd_birth_month,
        cd.cd_birth_year,
        c.c_current_addr_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
recent_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(rs.total_spent, 0) AS total_spent,
        rs.order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        recent_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.ca_city,
    t.ca_state,
    t.total_spent,
    t.order_count,
    CASE 
        WHEN t.order_count > 5 THEN 'Frequent Buyer'
        WHEN t.total_spent > 500 THEN 'High Spender'
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM 
    top_customers t
WHERE 
    t.total_spent >= (SELECT AVG(total_spent) FROM recent_sales)
ORDER BY 
    t.total_spent DESC,
    t.c_last_name ASC
LIMIT 10;
