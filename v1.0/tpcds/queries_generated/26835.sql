
SELECT 
    ca_state,
    SUBSTRING(ca_street_name, 1, 15) AS street_name_short,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    GROUP_CONCAT(DISTINCT cd_gender) AS genders,
    CONCAT(COUNT(DISTINCT c_customer_sk), ' customers in ', ca_city) AS customer_report,
    UPPER(ca_country) AS country_upper,
    LENGTH(ca_zip) AS zip_length
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca_state, ca_city, ca_zip, ca_street_name
HAVING 
    unique_customers > 10
ORDER BY 
    unique_customers DESC;
