
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           CAST(c_first_name || ' ' || c_last_name AS VARCHAR(100)) AS full_name,
           0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           CAST(h.full_name || ' -> ' || c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name,
           h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_current_addr_sk = h.c_current_addr_sk
    WHERE h.level < 5
)
SELECT ca.ca_city, ca.ca_state, COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
       MAX(ch.level) AS max_level,
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
WHERE ca.ca_state IN ('CA', 'NY') 
  AND (ch.c_customer_sk IS NOT NULL OR ca.ca_country IS NULL)
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT ch.c_customer_sk) > 0
ORDER BY total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
