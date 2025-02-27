
WITH RECURSIVE inventory_hierarchy AS (
    SELECT 
        inv_item_sk, 
        inv_quantity_on_hand, 
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM 
        inventory
), 
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            ELSE 'Standard'
        END AS customer_type
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent IS NOT NULL
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    (SELECT 
         AVG(total_spent) 
     FROM 
         high_value_customers 
     WHERE 
         customer_type = 'High Value') AS avg_high_value_spent,
    iv.inv_quantity_on_hand,
    CASE 
        WHEN hvc.total_spent > 5000 THEN 'VIP'
        WHEN hvc.total_spent IS NULL THEN 'NO PURCHASE'
        ELSE 'Regular' 
    END AS customer_status
FROM 
    high_value_customers hvc
LEFT JOIN 
    inventory_hierarchy iv ON hvc.total_spent IS NOT NULL
WHERE 
    hvc.customer_type = 'High Value'
ORDER BY 
    hvc.total_spent DESC;
