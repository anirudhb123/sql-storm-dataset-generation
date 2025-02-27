
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
)
SELECT 
    ca.ca_state,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    AVG(cd.cd_dep_count) AS avg_dependents,
    COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN ws.ws_bill_customer_sk END) AS married_customers,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_sales_price) DESC) AS rank,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM web_sales ws
INNER JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_date >= DATEADD(DAY, -30, CURRENT_DATE)
    )
GROUP BY ca.ca_state
HAVING SUM(ws.ws_sales_price) > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sold_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_date >= DATEADD(DAY, -30, CURRENT_DATE)
    ))
ORDER BY total_sales DESC;
