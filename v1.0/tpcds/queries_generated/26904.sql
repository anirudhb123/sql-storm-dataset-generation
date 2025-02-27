
SELECT 
    ca.city AS city,
    COUNT(c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    MAX(cd_dep_count) AS max_dependents,
    MIN(cd_dep_count) AS min_dependents,
    STRING_AGG(DISTINCT ca_state, ', ') AS state_list,
    GROUP_CONCAT(DISTINCT CONCAT(cd_marital_status, ': ', COUNT(*)) ORDER BY cd_marital_status) AS marital_status_summary
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL
GROUP BY 
    ca.city
HAVING 
    COUNT(c.c_customer_id) > 10
ORDER BY 
    customer_count DESC;
