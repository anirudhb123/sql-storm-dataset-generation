
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    cd.gender AS customer_gender,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN cd.marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd.marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = c.c_first_sales_date_sk 
WHERE 
    d.d_year >= 2020 
    AND d.d_year <= 2023 
    AND ca.state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.city, ca.state, cd.gender
ORDER BY 
    address_city, address_state, customer_gender;
