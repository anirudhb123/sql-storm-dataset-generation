
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd.education_status, ', ') AS education_levels,
    SUM(CASE WHEN cd.marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    LENGTH(wp.url) AS avg_url_length
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_page wp ON c.c_customer_sk = wp.wp_customer_sk
WHERE 
    ca.city IS NOT NULL
    AND ca.state IS NOT NULL
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.customer_id) > 0
ORDER BY 
    address_city, address_state;
