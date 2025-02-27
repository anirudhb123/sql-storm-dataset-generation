
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        MAX(ws.ws_net_paid) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.order_count,
        cs.avg_order_value,
        cs.max_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.order_count,
    hvc.avg_order_value,
    hvc.max_order_value,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    AVG(wr.wr_return_amt) AS avg_return_amount
FROM 
    high_value_customers hvc
LEFT JOIN 
    web_returns wr ON hvc.c_customer_id = wr.wr_returning_customer_sk
GROUP BY 
    hvc.c_customer_id, hvc.total_spent, hvc.order_count, hvc.avg_order_value, hvc.max_order_value
HAVING 
    COUNT(DISTINCT wr.wr_order_number) > 0
ORDER BY 
    hvc.total_spent DESC
LIMIT 10;
