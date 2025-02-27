
WITH RECURSIVE address_hierarchy AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        1 AS level
    FROM 
        customer_address
    WHERE 
        ca_country IS NOT NULL

    UNION ALL

    SELECT
        a.ca_address_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ah.level + 1
    FROM 
        customer_address a
    INNER JOIN 
        address_hierarchy ah ON a.ca_state = ah.ca_state 
                             AND a.ca_city != ah.ca_city
) 
SELECT 
    c.c_customer_id,
    MAX(ah.level) AS address_levels,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT e.wp_web_page_id) AS unique_web_page_count
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_page e ON e.wp_customer_sk = c.c_customer_sk
LEFT JOIN 
    address_hierarchy ah ON ah.ca_city = c.c_birth_city AND ah.ca_state = c.c_birth_state
WHERE 
    cd.cd_gender = 'M' AND 
    (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL) AND 
    (ah.ca_country = 'USA' OR ah.ca_country IS NULL) AND
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_customer_sk = c.c_customer_sk
          AND ss.ss_sold_date_sk BETWEEN 
              (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND 
              (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    )
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(DISTINCT cd.cd_demo_sk) > 0
ORDER BY 
    address_levels DESC, 
    avg_purchase_estimate DESC;
