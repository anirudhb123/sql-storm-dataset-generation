
SELECT 
    ca_city,
    ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(CASE WHEN cd_gender = 'F' THEN cd_dep_count END) AS max_female_dependents,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
    LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS unique_street_names
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca_city IS NOT NULL
    AND ca_state IS NOT NULL
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_customers DESC, total_net_profit DESC
LIMIT 100;
