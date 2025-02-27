
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        NULL AS parent_customer,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.c_customer_sk AS parent_customer,
        ph.total_orders + COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ph.total_spent + SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        (SELECT c_customer_sk, 
                COUNT(DISTINCT ws_order_number) AS total_orders,
                SUM(ws_net_paid) AS total_spent
         FROM 
                web_sales 
         GROUP BY c_customer_sk) ph ON c.c_customer_sk = ph.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.c_customer_sk, ph.total_orders, ph.total_spent
)
SELECT 
    sh.c_customer_sk, 
    sh.c_first_name, 
    sh.c_last_name, 
    sh.total_orders,
    sh.total_spent,
    CASE 
        WHEN sh.total_orders > 10 THEN 'High Value'
        WHEN sh.total_orders BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    (SELECT AVG(total_spent) FROM sales_hierarchy) AS average_spent,
    ROUND(((sh.total_spent - (SELECT AVG(total_spent) FROM sales_hierarchy)) / NULLIF((SELECT AVG(total_spent) FROM sales_hierarchy), 0)) * 100), 2) AS percentile_difference
FROM 
    sales_hierarchy sh
WHERE 
    sh.total_spent IS NOT NULL
ORDER BY 
    sh.total_spent DESC;
