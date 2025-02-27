
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(ca_street_name)) AS formatted_street_name,
        REPLACE(REPLACE(ca_city, ' ', '_'), '-', '_') AS modified_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_suite_number) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS address_info
    FROM 
        customer_address
), customer_order_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN 'Has Orders' ELSE 'No Orders' END) AS order_status
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ca.formatted_street_name,
    ca.modified_city,
    ca.full_address,
    ca.address_info,
    cus.c_first_name,
    cus.c_last_name,
    cus.total_spent,
    cus.total_orders,
    cus.order_status
FROM 
    processed_addresses ca
JOIN 
    customer_order_summary cus ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    ca.city LIKE 'New%' AND cus.total_spent > 1000
ORDER BY 
    ca.formatted_street_name, cus.total_spent DESC
LIMIT 100;
