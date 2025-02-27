
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
        c.c_birth_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ch.c_customer_sk) AS number_of_customers,
    AVG(cd.cd_purchase_estimate) FILTER (WHERE cd.cd_credit_rating IS NOT NULL) AS avg_purchase,
    MAX(cd.cd_dep_count) OVER (PARTITION BY ca.ca_state) AS max_dependents,
    STRING_AGG(DISTINCT cd.cd_gender, ', ') AS unique_genders
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_hierarchy ch ON ch.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_country IS NOT NULL
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('M', 'S'))
    AND (cd.cd_dep_count > 0 OR cd.cd_credit_rating LIKE 'Good%')
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ch.c_customer_sk) > 5
ORDER BY 
    number_of_customers DESC
LIMIT 10 OFFSET (SELECT COUNT(DISTINCT c_customer_sk) * 0.1 FROM customer)
UNION ALL
SELECT 
    'TOTAL' AS ca_city,
    COUNT(DISTINCT ch.c_customer_sk),
    SUM(cd.cd_purchase_estimate) OVER () AS avg_purchase,
    SUM(MAX(cd.cd_dep_count)) OVER () AS max_dependents,
    NULL AS unique_genders
FROM 
    customer_hierarchy ch
LEFT JOIN 
    customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_credit_rating IS NOT NULL
    AND cd.cd_dep_employed_count IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr 
        WHERE sr.sr_customer_sk = ch.c_customer_sk 
        HAVING SUM(sr.sr_return_quantity) > 10
    );
