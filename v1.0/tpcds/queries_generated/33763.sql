
WITH RECURSIVE Customer_CTE AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name, c_current_addr_sk,
           1 AS depth
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           cc.depth + 1
    FROM customer c
    INNER JOIN Customer_CTE cc ON c.c_current_addr_sk = cc.c_customer_sk
    WHERE cc.depth < 5
),
Sales_Summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk
),
Address_Projection AS (
    SELECT ca.ca_address_sk, 
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, 
                  ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_city, 
             ca.ca_state, ca.ca_zip
)
SELECT 
    cc.c_customer_id, 
    cc.c_first_name, 
    cc.c_last_name, 
    ap.full_address, 
    ss.total_profit,
    ss.total_orders,
    CASE 
        WHEN ss.total_profit > 1000 THEN 'High Value'
        WHEN ss.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM Customer_CTE cc
INNER JOIN Address_Projection ap ON cc.c_current_addr_sk = ap.ca_address_sk
LEFT JOIN Sales_Summary ss ON cc.c_customer_sk = ss.web_site_sk
WHERE cc.depth = 1
AND ap.customer_count > 5
ORDER BY ss.total_profit DESC
LIMIT 50;
