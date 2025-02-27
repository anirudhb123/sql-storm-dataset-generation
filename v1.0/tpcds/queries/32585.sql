
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
        JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)

SELECT 
    cha.ca_city,
    COUNT(DISTINCT cu.c_customer_sk) AS total_customers,
    SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate,
    AVG(CASE 
            WHEN cd.cd_credit_rating = 'M' THEN cd.cd_purchase_estimate 
            ELSE NULL 
        END) AS avg_purchase_estimate_marital,
    STRING_AGG(DISTINCT CONCAT(cu.c_first_name, ' ', cu.c_last_name), ', ') AS customer_names
FROM 
    customer_address cha 
LEFT JOIN 
    customer cu ON cha.ca_address_sk = cu.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_hierarchy ch ON cu.c_customer_sk = ch.c_customer_sk
WHERE 
    cha.ca_city IS NOT NULL 
    AND cha.ca_state = 'CA'
GROUP BY 
    cha.ca_city
HAVING 
    COUNT(DISTINCT cu.c_customer_sk) > 10
ORDER BY 
    total_purchase_estimate DESC
LIMIT 10;
