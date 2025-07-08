
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_credit_rating IN ('Good', 'Excellent')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
), 

top_customers AS (
    SELECT 
        cs.c_customer_sk,
        CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_profit
    FROM 
        customer_stats cs
    WHERE 
        cs.rank <= 10
)

SELECT 
    tc.full_name,
    CASE 
        WHEN tc.total_orders > 50 THEN 'High Value Customer' 
        WHEN tc.total_orders BETWEEN 20 AND 50 THEN 'Medium Value Customer' 
        ELSE 'Low Value Customer' 
    END AS customer_category,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.avg_profit, 0) AS avg_profit
FROM 
    top_customers tc
LEFT JOIN 
    store s ON s.s_store_sk = (
        SELECT s.s_store_sk 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = tc.c_customer_sk 
        ORDER BY ss.ss_sold_date_sk DESC
        LIMIT 1
    )
WHERE 
    s.s_store_sk IS NOT NULL
ORDER BY 
    tc.total_spent DESC;
