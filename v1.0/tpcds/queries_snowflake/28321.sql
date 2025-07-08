
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT ca_city, ', ') AS cities,
    SUM(ss_ext_sales_price) AS total_sales,
    MIN(cd_dep_count) AS min_dependents,
    MAX(cd_credit_rating) AS max_credit_rating
FROM 
    customer_address
INNER JOIN 
    customer ON ca_address_sk = c_current_addr_sk
INNER JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
LEFT JOIN 
    store_sales ON c_customer_sk = ss_customer_sk
WHERE 
    cd_gender = 'F' 
    AND ca_country = 'USA'
    AND cd_marital_status = 'M'
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC;
