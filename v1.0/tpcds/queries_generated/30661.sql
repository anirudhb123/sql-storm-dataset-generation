
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           c_birth_year, 
           NULL as parent_customer_sk
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.c_birth_year, 
           ch.c_customer_sk
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_customer_sk
)
SELECT 
    ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(CASE WHEN cd_marital_status = 'M' THEN cd_dep_count ELSE NULL END) AS avg_dependent_count,
    SUM(ws_net_profit) AS total_profit,
    STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ': ', p.p_cost), '; ') AS promo_details
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE ca.ca_state IS NOT NULL 
AND (c.c_birth_year BETWEEN 1990 AND 2000 OR c.c_birth_year IS NULL)
GROUP BY ca_state
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY customer_count DESC
; 
