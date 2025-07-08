
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
    LISTAGG(DISTINCT CASE 
        WHEN cd_gender = 'M' THEN 'Male' 
        WHEN cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' END, ', ') WITHIN GROUP (ORDER BY cd_gender) AS gender_distribution,
    LISTAGG(DISTINCT CASE 
        WHEN cd_marital_status = 'M' THEN 'Married' 
        WHEN cd_marital_status = 'S' THEN 'Single' 
        ELSE 'Other' END, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_status_distribution
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_city,
    cd_purchase_estimate,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    customer_count DESC;
