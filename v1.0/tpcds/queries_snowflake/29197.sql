
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd_dep_count) AS max_dependents,
    MIN(cd_dep_count) AS min_dependents,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city LIKE '%New%' 
    AND cd_credit_rating IN ('Good', 'Excellent')
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
