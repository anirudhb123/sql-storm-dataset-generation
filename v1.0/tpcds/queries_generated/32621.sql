
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_returning_customer_sk FROM store_returns)

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.city,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(ws.ws_net_paid) AS max_paid,
    MIN(ws.ws_net_paid) AS min_paid,
    CASE 
        WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High Revenue'
        WHEN SUM(ws.ws_net_paid) BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    CustomerHierarchy ch
JOIN 
    customer c ON ch.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_country = 'United States')
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT ch.c_customer_sk) > 5
ORDER BY 
    total_customers DESC;
