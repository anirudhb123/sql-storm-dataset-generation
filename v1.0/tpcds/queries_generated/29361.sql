
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
    TRIM(COALESCE(MAX(cd_marital_status), 'Unknown')) AS marital_status,
    MAX(d_year) AS latest_year,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
FROM 
    customer AS c 
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim AS dd ON ss.ss_sold_date_sk = dd.d_date_sk 
WHERE 
    dd.d_year >= 2020 
    AND ca_country = 'United States'
GROUP BY 
    ca_city, ca_state 
ORDER BY 
    unique_customers DESC, ca_city;
