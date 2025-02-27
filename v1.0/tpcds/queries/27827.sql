
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd.cd_credit_rating) AS unique_credit_ratings,
    STRING_AGG(DISTINCT CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS customer_full_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_customers DESC;
