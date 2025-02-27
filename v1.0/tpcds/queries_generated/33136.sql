
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(NULLIF(cd.cd_dep_count, 0), 1)) AS total_dependencies,
    AVG(cd.cd_purchase_estimate) AS average_estimated_purchase,
    MAX(cd.cd_credit_rating = 'Excellent') AS excellent_credit_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_net_profit DESC
LIMIT 100;
