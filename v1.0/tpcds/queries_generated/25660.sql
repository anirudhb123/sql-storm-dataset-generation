
WITH AddressInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
), 
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        d.d_date AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    ai.customer_name,
    ai.full_address,
    COUNT(si.ws_order_number) AS total_orders,
    SUM(si.ws_quantity) AS total_items,
    SUM(si.ws_net_paid) AS total_spent
FROM 
    AddressInfo ai
LEFT JOIN 
    SalesInfo si ON ai.customer_name = (SELECT CONCAT(c.c_first_name, ' ', c.c_last_name) FROM customer c WHERE c.c_customer_sk = si.ws_bill_customer_sk)
GROUP BY 
    ai.customer_name, ai.full_address
HAVING 
    total_orders > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
