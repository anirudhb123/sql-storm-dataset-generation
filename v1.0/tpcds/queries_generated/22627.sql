
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_zip, 1 AS level
    FROM customer_address
    WHERE ca_country = 'USA'
    
    UNION ALL
    
    SELECT ca.ca_address_sk, 
           CONCAT(ca.ca_street_name, ' / ', ah.ca_street_name),
           ah.ca_city,
           ah.ca_state,
           ah.ca_zip, 
           ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_state IS NOT NULL AND ah.level < 5
),
customer_summary AS (
    SELECT c.c_customer_id, 
           COUNT(DISTINCT cs.ss_ticket_number) AS store_sales_count,
           SUM(cs.ss_ext_sales_price) AS total_store_sales,
           SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
state_sales AS (
    SELECT ca.ca_state, 
           SUM(cs.ss_net_profit) AS state_profit,
           SUM(ws.ws_net_profit) AS state_web_profit
    FROM customer_address ca
    LEFT JOIN store_sales cs ON cs.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT ah.ca_city, 
       ah.ca_state, 
       SUM(cs.store_sales_count) AS total_sales_count,
       SUM(cs.total_store_sales) AS total_store_sales,
       SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_store_and_web_sales,
       MAX(ss.state_profit) AS max_state_profit,
       MAX(ss.state_web_profit) AS max_web_profit,
       COUNT(DISTINCT cd.cd_demo_sk) FILTER (WHERE cd.cd_marital_status = 'M') AS married_customers,
       COUNT(DISTINCT cd.cd_demo_sk) FILTER (WHERE cd.cd_marital_status IS NULL) AS unknown_marital_status,
       SUM(CASE WHEN cs.ss_quantity < 0 THEN 1 ELSE 0 END) AS negative_sales_count
FROM address_hierarchy ah
LEFT JOIN customer_summary cs ON cs.c_customer_id IN (
    SELECT c.c_customer_id 
    FROM customer c 
    WHERE c.c_current_addr_sk = ah.ca_address_sk
)
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.c_customer_id
LEFT JOIN state_sales ss ON ss.ca_state = ah.ca_state
WHERE ah.level = (
    SELECT MAX(level) 
    FROM address_hierarchy
)
GROUP BY ah.ca_city, ah.ca_state
HAVING total_store_sales > 100
ORDER BY total_store_sales DESC NULLS LAST;
