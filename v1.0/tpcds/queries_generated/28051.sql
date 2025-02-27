
SELECT 
    CONCAT(SUBSTRING(c.c_first_name, 1, 1), '. ', c.c_last_name) AS customer_name,
    REPLACE(ca.ca_street_name, 'Street', 'St.') AS formatted_street_name,
    CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
    LOWER(c.c_email_address) AS normalized_email,
    DENSE_RANK() OVER (PARTITION BY c.ca_city ORDER BY c.c_birth_year) AS city_rank,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status), ', ') AS demographics
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    c.c_preferred_cust_flag = 'Y' 
    AND ca.ca_zip LIKE '1%'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_name, 
    ca.ca_city, ca.ca_state, ca.ca_zip, c.c_email_address, 
    c.c_birth_year
ORDER BY 
    city_rank DESC, customer_name ASC;
