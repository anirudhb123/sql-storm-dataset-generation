
WITH RECURSIVE CustomerPaths AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        1 AS path_length,
        CAST(c.c_customer_id AS VARCHAR(255)) AS path
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cp.path_length + 1,
        CONCAT(cp.path, ' -> ', c.c_customer_id)
    FROM customer c
    JOIN CustomerPaths cp ON c.c_current_cdemo_sk = cp.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cp.path_length < 5
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.cd_gender,
    cp.path_length,
    STRING_AGG(cp.path, ', ') AS full_path
FROM CustomerPaths cp
GROUP BY cp.c_customer_sk, cp.c_first_name, cp.c_last_name, cp.cd_gender, cp.path_length
HAVING COUNT(*) > 1
ORDER BY cp.path_length, cp.c_last_name;

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('CA', 'NY')
GROUP BY ca.ca_city
HAVING customer_count > 10
ORDER BY customer_count DESC

UNION ALL

SELECT 
    'Total Customers' AS city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count
FROM customer c
WHERE c.c_birth_year < 1980
AND c.c_customer_id IS NOT NULL;

SELECT 
    d.d_date,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid_inc_tax) AS avg_revenue,
    MAX(ws.ws_ext_discount_amt) AS max_discount
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023 AND d.d_dow IN (6, 7)
GROUP BY d.d_date
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY d.d_date DESC
LIMIT 30;
