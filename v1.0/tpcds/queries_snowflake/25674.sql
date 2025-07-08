
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases, 
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
), 

HighValueCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        ca_city,
        ca_state,
        full_name,
        total_purchases,
        total_spent,
        CASE 
            WHEN total_spent > 10000 THEN 'High Value'
            WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        CustomerStats
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(*) AS customer_count,
    SUM(hvc.total_purchases) AS total_purchases,
    SUM(hvc.total_spent) AS total_spent,
    AVG(hvc.total_spent) AS avg_spent_per_customer,
    LISTAGG(hvc.full_name, ', ') AS customer_names
FROM 
    HighValueCustomers hvc
JOIN 
    customer_address ca ON hvc.c_customer_id = ca.ca_address_id 
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC;
