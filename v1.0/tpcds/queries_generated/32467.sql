
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level, c_current_addr_sk
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1, c.c_current_addr_sk
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(cd.cd_dep_count) AS min_dependents,
    ROUND(SUM(COALESCE(ws.ws_net_profit, 0)), 2) AS total_net_profit,
    SM.sm_type AS shipping_mode,
    D.d_year AS sales_year
FROM CustomerHierarchy ch
LEFT JOIN customer_demographics cd ON ch.c_customer_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ship_mode SM ON ws.ws_ship_mode_sk = SM.sm_ship_mode_sk
JOIN date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
WHERE cd.cd_marital_status = 'M'
AND ca.ca_state IN ('CA', 'NY')
GROUP BY ca.ca_city, SM.sm_type, D.d_year
HAVING COUNT(DISTINCT ch.c_customer_sk) > 5
ORDER BY total_net_profit DESC;
