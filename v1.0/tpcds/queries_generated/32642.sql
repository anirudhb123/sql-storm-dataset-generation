
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk, 
        0 AS level
    FROM 
        customer 
    WHERE 
        c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    INNER JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca_state,
    COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
    SUM(COALESCE(cd_purchase_estimate, 0)) AS total_purchase_estimate,
    AVG(COALESCE(cd_dep_count, 0)) AS average_dependents,
    MAX(cd_credit_rating) AS highest_credit_rating,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    STRING_AGG(DISTINCT CONCAT(ch.c_first_name, ' ', ch.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca 
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
LEFT JOIN 
    CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk 
GROUP BY 
    ca_state 
HAVING 
    COUNT(DISTINCT ch.c_customer_sk) > 0 
ORDER BY 
    customer_count DESC;

