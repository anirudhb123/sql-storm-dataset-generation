
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_current_cdemo_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_first_name IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_current_cdemo_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND (ch.level > 1 OR ch.c_first_name IS NULL)
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_net_profit DESC
LIMIT 10;
