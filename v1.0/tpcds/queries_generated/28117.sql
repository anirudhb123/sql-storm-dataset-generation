
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names,
    MAX(cd_dep_count) AS max_dependents,
    MIN(cd_dep_employed_count) AS min_employed_dependents,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
