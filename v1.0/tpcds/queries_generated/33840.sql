
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_customer_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
    SUM(CASE 
        WHEN cd.cd_marital_status = 'M' THEN 1 
        ELSE 0 
    END) AS married_customers,
    STRING_AGG(DISTINCT CONCAT(ch.c_first_name, ' ', ch.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_hierarchy ch ON ch.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state = 'NY'
GROUP BY 
    ca.ca_city
ORDER BY 
    total_customers DESC
LIMIT 10;
