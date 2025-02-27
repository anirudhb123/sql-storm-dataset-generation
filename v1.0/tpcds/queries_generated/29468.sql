
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT concat(cd_education_status, ' (', cd_marital_status, ')') ORDER BY cd_education_status) AS education_marital_status_summary,
    SUM(CASE WHEN cd_dep_college_count > 0 THEN 1 ELSE 0 END) AS customers_with_college_dependent
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_customers DESC;
