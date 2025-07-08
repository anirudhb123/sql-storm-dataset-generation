
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    LISTAGG(DISTINCT cd.cd_education_status, ', ') WITHIN GROUP (ORDER BY cd.cd_education_status) AS unique_education_status,
    COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_id END) AS married_count,
    COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'S' THEN c.c_customer_id END) AS single_count
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim dd ON c.c_first_shipto_date_sk = dd.d_date_sk
WHERE 
    ca.ca_state = 'CA' AND 
    dd.d_year = 2023
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_customers DESC;
