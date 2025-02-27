
SELECT 
    ca.city AS city, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT IIF(cd_marital_status = 'M', 'Married', 'Single'), ', ') AS marital_status_summary,
    STRING_AGG(DISTINCT ca_state, ', ') AS states_summary
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY 
    customer_count DESC;
