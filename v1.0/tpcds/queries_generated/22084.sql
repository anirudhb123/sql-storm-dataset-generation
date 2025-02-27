
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state
    WHERE ah.level < 5
)

SELECT 
    c.c_customer_id, 
    d.d_year, 
    (SUM(ws.ws_sales_price) - SUM(ws.ws_ext_discount_amt)) AS total_sales,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    COALESCE(CAST(NULLIF(m.dow, 0) AS VARCHAR), 'No Data') AS day_of_week,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    AVG(ws.ws_net_paid) OVER (PARTITION BY d.d_year) AS avg_net_paid_year
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    address_hierarchy ah ON c.c_current_addr_sk = ah.ca_address_sk
WHERE 
    d.d_year = 2023 
    AND c.c_birth_country IS NOT NULL
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address LIKE '%@example.com')
GROUP BY 
    c.c_customer_id, d.d_year, full_name, day_of_week
HAVING 
    total_sales > 1000 
    AND order_status = 'Has Orders'
ORDER BY 
    total_sales DESC
LIMIT 100;
