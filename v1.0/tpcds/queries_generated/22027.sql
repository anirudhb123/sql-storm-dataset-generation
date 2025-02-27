
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state,
           1 AS level 
    FROM customer_address 
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_street_name, 
           ca.ca_city, ca.ca_state, 
           ah.level + 1 
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
      AND ah.level < 5
), 
purchase_data AS (
    SELECT ws.bill_customer_sk, SUM(ws.net_profit) AS total_profit,
           COUNT(DISTINCT ws.order_number) AS total_orders
    FROM web_sales ws
    LEFT JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_login IS NULL)
      AND ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.bill_customer_sk
), 
ranked_customers AS (
    SELECT pd.bill_customer_sk, pd.total_profit,
           ROW_NUMBER() OVER (PARTITION BY pd.bill_customer_sk ORDER BY pd.total_profit DESC) AS rnk
    FROM purchase_data pd
    WHERE pd.total_orders > 0
)
SELECT DISTINCT 
    ah.ca_address_id, 
    ah.ca_street_name,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    rc.total_profit,
    rc.rnk
FROM address_hierarchy ah
JOIN customer c ON c.c_current_addr_sk = ah.ca_address_sk
LEFT JOIN ranked_customers rc ON rc.bill_customer_sk = c.c_customer_sk
WHERE clmt IS NOT NULL
  AND (rc.rnk <= 5 OR rc.total_profit IS NULL)
ORDER BY ah.ca_city, rc.total_profit DESC
OFFSET (SELECT COUNT(*) FROM ranked_customers WHERE total_profit > 1000) ROWS
FETCH NEXT 10 ROWS ONLY;
