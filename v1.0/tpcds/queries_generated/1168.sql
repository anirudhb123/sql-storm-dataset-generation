
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), avg_sales AS (
    SELECT 
        AVG(total_profit) AS avg_profit,
        AVG(order_count) AS avg_orders
    FROM 
        customer_sales
), high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.order_count,
        CASE 
            WHEN cs.total_profit > a.avg_profit THEN 'Above Average'
            ELSE 'Below Average'
        END AS profit_category
    FROM 
        customer_sales cs
    CROSS JOIN 
        avg_sales a
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_profit,
    hvc.order_count,
    hvc.profit_category
FROM 
    high_value_customers hvc
WHERE 
    hvc.order_count > 5
ORDER BY 
    hvc.total_profit DESC
LIMIT 10
UNION ALL
SELECT 
    ca.ca_address_sk AS c_customer_sk,
    NULL AS c_first_name,
    NULL AS c_last_name,
    0 AS total_profit,
    0 AS order_count,
    'No Sales' AS profit_category
FROM 
    customer_address ca
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_current_addr_sk = ca.ca_address_sk
    )
ORDER BY 
    total_profit DESC;
