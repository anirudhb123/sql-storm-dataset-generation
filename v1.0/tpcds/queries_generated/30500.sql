
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1980

    UNION ALL

    SELECT 
        child.c_customer_sk,
        child.c_first_name,
        child.c_last_name,
        parent.cd_marital_status,
        parent.cd_gender,
        level + 1
    FROM 
        customer c AS child
    JOIN 
        customer c AS parent ON child.c_birth_month = parent.c_birth_month AND child.c_birth_day = parent.c_birth_day
    JOIN 
        customer_demographics cd ON parent.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        level < 5
)

SELECT 
    ca.ca_country, 
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
    STRING_AGG(CONCAT_WS(' ', c.c_first_name, c.c_last_name) ORDER BY c.c_last_name) AS customer_names,
    SUM(CASE 
        WHEN cd.cd_gender = 'F' THEN 1 
        ELSE 0 
    END) AS female_count,
    SUM(CASE 
        WHEN cd.cd_gender = 'M' THEN 1 
        ELSE 0 
    END) AS male_count
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = c.c_customer_sk 
        AND ss.ss_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    )
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    unique_customers DESC;
