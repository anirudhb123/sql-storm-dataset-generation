
SELECT 
    SUBSTRING(c.c_first_name, 1, 1) AS first_initial, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate, 
    STRING_AGG(DISTINCT ca.ca_city, ', ') AS unique_cities,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(sr_return_quantity) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cd.cd_education_status LIKE 'Bachelor%'
    AND ca.ca_state IN ('CA', 'TX')
GROUP BY 
    first_initial
ORDER BY 
    first_initial;
