
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           1 AS hierarchy_level, c.c_current_cdemo_sk AS demo_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           ch.hierarchy_level + 1,
           c.c_current_cdemo_sk
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.demo_sk
)

SELECT ca.ca_city, COUNT(DISTINCT c.c_customer_sk) AS total_customers,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
       SUM(ws.ws_net_profit) AS total_profit,
       SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns,
       STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM customer_hierarchy ch
JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY ca.ca_city
HAVING AVG(cd.cd_purchase_estimate) > (
    SELECT AVG(cd_inner.cd_purchase_estimate)
    FROM customer_demographics cd_inner 
    WHERE cd_inner.cd_gender = 'M'
)
ORDER BY total_profit DESC
LIMIT 10;
