
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT cd_credit_rating, ', ') WITHIN GROUP (ORDER BY cd_credit_rating) AS unique_credit_ratings,
    SUM(CASE WHEN ca_state = 'CA' THEN cd_dep_count ELSE 0 END) AS total_dependent_count_CA,
    MAX(LENGTH(c_first_name) + LENGTH(c_last_name)) AS max_full_name_length,
    MIN(LENGTH(c_email_address)) AS min_email_length,
    COUNT(DISTINCT c_email_address) FILTER (WHERE c_email_address LIKE '%@%.com') AS valid_email_count
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
WHERE 
    ca_country = 'USA'
GROUP BY 
    ca_city, c_customer_id, cd_purchase_estimate, cd_credit_rating, cd_dep_count, c_first_name, c_last_name, c_email_address
ORDER BY 
    customer_count DESC
LIMIT 10;
