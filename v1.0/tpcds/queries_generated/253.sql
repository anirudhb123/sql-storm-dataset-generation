
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.unique_items,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rn
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent IS NOT NULL
),
top_customers AS (
    SELECT 
        c.rn,
        c.c_first_name,
        c.c_last_name,
        c.total_spent,
        CASE 
            WHEN c.total_orders > 10 THEN 'High Value' 
            WHEN c.total_orders BETWEEN 5 AND 10 THEN 'Medium Value' 
            ELSE 'Low Value' 
        END AS customer_value_segment
    FROM 
        sales_analysis c
    WHERE 
        c.rn <= 50
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.customer_value_segment,
    IFNULL(NULLIF(tc.total_orders, 0), 1) AS effective_orders,
    ROUND(tc.total_spent / NULLIF(tc.total_orders, 0), 2) AS avg_spent_per_order
FROM 
    top_customers tc
ORDER BY 
    tc.total_spent DESC;
