
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        customer_sales cs
),
return_stats AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN tc.total_net_profit > 1000 THEN 'High Value'
        WHEN tc.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    top_customers tc
LEFT JOIN 
    return_stats rs ON tc.c_customer_sk = rs.returning_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
