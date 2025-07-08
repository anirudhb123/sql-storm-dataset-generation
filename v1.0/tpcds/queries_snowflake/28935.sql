
SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
    SUM(ss.ss_quantity) AS total_store_sales,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), '; ') WITHIN GROUP (ORDER BY c.c_first_name) AS customer_names,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_country IS NOT NULL AND
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_country
ORDER BY 
    unique_customers DESC
LIMIT 10;
