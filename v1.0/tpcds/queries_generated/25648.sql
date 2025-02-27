
WITH Addressed_Customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_street_number, 
        ca.ca_street_name, 
        ca.ca_street_type, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip
), Purchase_Stats AS (
    SELECT 
        full_name,
        full_address,
        ca_city,
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        Addressed_Customers
    JOIN web_sales ws ON Addressed_Customers.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        full_name, 
        full_address, 
        ca_city, 
        ca_state
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    total_sales,
    avg_sales_price,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    Purchase_Stats
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_sales DESC;
