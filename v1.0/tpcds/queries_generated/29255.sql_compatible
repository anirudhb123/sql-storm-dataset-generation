
WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    ' ', COALESCE(ca_suite_number, ''), ', ', ca_city, ', ', 
                    ca_state, ' ', ca_zip, ', ', ca_country)) AS full_address
    FROM 
        customer_address
),
frequent_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
),
address_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_address_sk,
        ca.full_address
    FROM 
        frequent_customers fc
    JOIN 
        customer c ON fc.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ai.c_customer_sk,
    ai.full_address,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
FROM 
    address_info ai
LEFT JOIN 
    web_sales ws ON ai.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ai.c_customer_sk, ai.full_address
ORDER BY 
    total_spent DESC
LIMIT 10;
