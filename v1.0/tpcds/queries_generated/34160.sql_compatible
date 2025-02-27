
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
)
SELECT 
    ch.c_customer_sk,
    CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
    ch.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_spent,
    MAX(ws.ws_sales_price) AS max_order_value,
    CASE 
        WHEN AVG(ws.ws_sales_price) IS NULL THEN 'No orders'
        WHEN AVG(ws.ws_sales_price) > 100 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ch.c_customer_sk, 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.cd_gender
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 50 OFFSET 0;
