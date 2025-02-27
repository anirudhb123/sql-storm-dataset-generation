
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
WHERE ca.ca_country IS NOT NULL 
  AND (c.c_birth_year < 1990 OR c.c_birth_month IN (1, 6)) 
  AND (c.c_preferred_cust_flag = 'Y' AND c.c_login IS NOT NULL)
GROUP BY ca.ca_country
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY total_net_profit DESC;
