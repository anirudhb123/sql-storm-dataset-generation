
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tb.avg_spent, 0) AS average_spent_by_gender,
    CASE 
        WHEN tc.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    top_customers tc
JOIN 
    (SELECT 
         cd.cd_gender, 
         AVG(total_spent) AS avg_spent
     FROM 
         top_customers
     GROUP BY 
         cd_gender) tb ON tc.cd_gender = tb.cd_gender
WHERE 
    tc.total_spent > 1000
ORDER BY 
    tc.total_spent DESC
LIMIT 50;
