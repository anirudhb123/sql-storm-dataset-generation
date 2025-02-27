
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spending,
        CASE 
            WHEN cs.total_spending >= 500 THEN 'High'
            WHEN cs.total_spending >= 250 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value 
    FROM 
        customer_sales cs
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_orders,
    hvc.total_spending,
    hvc.customer_value,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    SUM(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN sr.sr_return_amt ELSE 0 END) AS total_returned_amount,
    AVG(ws.ws_net_profit) OVER (PARTITION BY hvc.customer_value) AS avg_profit_by_value
FROM 
    high_value_customers hvc
LEFT JOIN 
    store_returns sr ON hvc.c_customer_sk = sr.sr_customer_sk 
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    hvc.total_spending > 0
GROUP BY 
    hvc.c_first_name, hvc.c_last_name, hvc.total_orders, hvc.total_spending, hvc.customer_value
ORDER BY 
    hvc.total_spending DESC;
