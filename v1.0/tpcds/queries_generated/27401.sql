
SELECT 
    ca_city,
    ca_state,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    MIN(cd_purchase_estimate) AS min_purchase_estimate,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_statuses
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city IS NOT NULL AND
    ca_state IS NOT NULL
GROUP BY 
    ca_city, ca_state
ORDER BY 
    ca_state, ca_city;
