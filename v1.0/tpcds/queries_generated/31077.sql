
WITH RECURSIVE customer_chain AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS chain_level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           cc.chain_level + 1
    FROM customer c
    JOIN customer_chain cc ON c.c_current_addr_sk = cc.c_current_addr_sk
    WHERE cc.chain_level < 5
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_wholesale_cost) AS total_wholesale_cost,
           SUM(ws_net_paid) AS total_net_paid,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_bill_customer_sk
),
address_summary AS (
    SELECT ca_address_sk, 
           ca_city, 
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_sk, ca_city
),
final_summary AS (
    SELECT cc.c_first_name,
           cc.c_last_name,
           coalesce(ss.total_net_paid, 0) AS total_net_paid,
           coalesce(ss.total_orders, 0) AS total_orders,
           abs(as.customer_count) AS address_count,
           ROW_NUMBER() OVER (PARTITION BY cc.c_current_addr_sk ORDER BY ss.total_net_paid DESC) AS rank
    FROM customer_chain cc
    LEFT JOIN sales_summary ss ON cc.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN address_summary as ON cc.c_current_addr_sk = as.ca_address_sk
    WHERE cc.chain_level = (SELECT MAX(chain_level) FROM customer_chain)
)
SELECT f.c_first_name, 
       f.c_last_name,
       f.total_net_paid,
       f.total_orders,
       f.address_count
FROM final_summary f
WHERE f.total_net_paid > 500
ORDER BY f.total_net_paid DESC
FETCH FIRST 10 ROWS ONLY;
