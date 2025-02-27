
WITH RECURSIVE CustomerTree AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 0 AS level
    FROM customer c
    WHERE c.c_birth_year >= 1970
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ct.level + 1
    FROM customer c
    JOIN CustomerTree ct ON ct.c_customer_sk = c.c_current_cdemo_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS rank_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IS NOT NULL AND 
    d.d_year = 2023 
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY 
    total_customers DESC
LIMIT 10;
