
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT ca_city || ' - ' || ca_street_name || ' ' || ca_street_number, '; ') WITHIN GROUP (ORDER BY ca_city) AS address_details
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
