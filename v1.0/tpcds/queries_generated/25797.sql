
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_last_name, c.c_first_name) AS customer_names,
    SUM(CASE 
        WHEN cd.cd_gender = 'F' THEN 1 
        ELSE 0 
    END) AS female_count,
    SUM(CASE 
        WHEN cd.cd_gender = 'M' THEN 1 
        ELSE 0 
    END) AS male_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    address_city, address_state;
