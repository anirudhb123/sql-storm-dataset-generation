
SELECT 
    ca.city AS city,
    COUNT(*) AS customer_count,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names,
    AVG(cd.purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT c.email_address, ', ') AS email_addresses,
    MAX(cd.dep_count) AS max_dependents,
    STRING_AGG(DISTINCT cd.credit_rating, ', ') AS credit_ratings,
    COUNT(DISTINCT CASE WHEN cd.gender = 'M' THEN c.c_customer_sk END) AS male_customers,
    COUNT(DISTINCT CASE WHEN cd.gender = 'F' THEN c.c_customer_sk END) AS female_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca.city
ORDER BY 
    customer_count DESC;
