
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.total_orders, 
        rc.total_profit, 
        rc.gender_rank
    FROM 
        ranked_customers rc
    WHERE 
        rc.total_orders > 5 AND rc.gender_rank <= 10
)
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_orders, 
    tc.total_profit, 
    cd.ca_city, 
    cd.ca_state 
FROM 
    top_customers tc
JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON dd.d_date_sk = CURRENT_DATE
WHERE 
    dd.d_year = 2023
ORDER BY 
    tc.total_profit DESC;
