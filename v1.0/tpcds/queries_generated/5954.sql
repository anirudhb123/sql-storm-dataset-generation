
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_purchases
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_profit > 1000 AND cs.total_purchases > 5
),
average_sales AS (
    SELECT 
        AVG(total_profit) AS avg_profit,
        AVG(total_purchases) AS avg_purchases
    FROM 
        high_value_customers
),
customer_percent AS (
    SELECT 
        customer_sk,
        (total_profit / a.avg_profit * 100) AS profit_percentage,
        (total_purchases / a.avg_purchases * 100) AS purchase_percentage
    FROM 
        high_value_customers hvc, average_sales a
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cp.profit_percentage,
    cp.purchase_percentage
FROM 
    high_value_customers hvc
JOIN 
    customer_percent cp ON hvc.c_customer_sk = cp.customer_sk
ORDER BY 
    cp.profit_percentage DESC, cp.purchase_percentage DESC;
