
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
top_customers AS (
    SELECT 
        c.customer_sk, 
        c.first_name, 
        c.last_name, 
        cs.total_spent, 
        cs.total_orders, 
        cs.average_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
    JOIN 
        (SELECT c_customer_sk, c_first_name AS first_name, c_last_name AS last_name
        FROM customer) c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name, 
    tc.last_name, 
    tc.total_spent, 
    tc.total_orders,
    tc.average_order_value
FROM 
    top_customers tc
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_spent DESC;
