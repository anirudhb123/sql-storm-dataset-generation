
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
),
orders_summary AS (
    SELECT 
        coalesce(ws_bill_customer_sk, cs_bill_customer_sk, ss_customer_sk) AS customer_id,
        SUM(coalesce(ws_net_paid, cs_net_paid, ss_net_paid)) AS total_spent,
        COUNT(DISTINCT coalesce(ws_order_number, cs_order_number, ss_ticket_number)) AS total_orders
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws_bill_customer_sk = cs_bill_customer_sk
    FULL OUTER JOIN 
        store_sales ss ON ws_bill_customer_sk = ss_customer_sk
    GROUP BY 
        customer_id
),
high_value_customers AS (
    SELECT 
        c.customer_id,
        c.c_first_name,
        c.c_last_name,
        o.total_spent,
        o.total_orders,
        DENSE_RANK() OVER (ORDER BY o.total_spent DESC) AS rank
    FROM 
        (SELECT DISTINCT c_customer_sk AS customer_id, c_first_name, c_last_name FROM customer) c
    JOIN 
        orders_summary o ON c.customer_id = o.customer_id
    WHERE 
        o.total_spent IS NOT NULL AND
        o.total_spent > (SELECT AVG(total_spent) FROM orders_summary)
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    hvc.total_spent,
    hvc.total_orders,
    hvc.rank
FROM 
    customer_hierarchy h
JOIN 
    high_value_customers hvc ON h.c_customer_sk = hvc.customer_id
WHERE 
    h.level <= 3
ORDER BY 
    hvc.rank,
    h.c_last_name;
