
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 2
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_paid_inc_tax) > 1000
    ORDER BY total_spent DESC
    LIMIT 10
),
address_details AS (
    SELECT ca.ca_address_sk, CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
),
sales_summary AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sold, AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ad.full_address,
    tc.total_spent,
    ss.total_sold,
    ss.average_profit
FROM customer_hierarchy ch
LEFT JOIN address_details ad ON ch.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN top_customers tc ON ch.c_customer_sk = tc.c_customer_sk
LEFT JOIN sales_summary ss ON ss.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
WHERE ch.level = 1
ORDER BY tc.total_spent DESC, ss.average_profit DESC
LIMIT 5;
