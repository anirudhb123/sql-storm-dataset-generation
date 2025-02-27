
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           CAST(NULL AS VARCHAR(255)) AS parent_customer,
           0 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           ch.c_first_name || ' ' || ch.c_last_name AS parent_customer,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(cd.cd_dep_count) AS avg_dependents,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' - ', cd.cd_credit_rating), '; ') AS demographic_summary
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND cd.cd_marital_status IS NOT NULL
    AND (cd.cd_purchase_estimate > 1000 OR cd.cd_credit_rating IS NOT NULL)
    AND (ws.ws_ship_date_sk BETWEEN 2000 AND 2023)
    AND NOT EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = ws.ws_warehouse_sk
        AND s.s_state = 'TX'
    )
GROUP BY ca.ca_state
HAVING COUNT(DISTINCT ch.c_customer_sk) > 10
ORDER BY total_net_profit DESC
LIMIT 10;
