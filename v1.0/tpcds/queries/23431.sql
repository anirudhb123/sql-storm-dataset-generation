
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_year,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        ch.c_birth_year,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer_address ca ON ch.c_customer_sk = ca.ca_address_sk
    WHERE 
        ch.level < 10
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
    COUNT(DISTINCT ca.ca_zip) AS unique_zip_codes,
    SUM(
        CASE 
            WHEN ch.c_birth_year BETWEEN 1980 AND 2000 THEN 1 
            ELSE 0 
        END
    ) AS birth_year_range_count
FROM 
    CustomerHierarchy ch
JOIN 
    customer_address ca ON ch.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON ch.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    (SELECT DISTINCT 
        sr_customer_sk 
     FROM 
         store_returns 
     GROUP BY 
         sr_customer_sk 
     HAVING 
         SUM(sr_return_quantity) > 3
    ) sr ON ch.c_customer_sk = sr.sr_customer_sk
WHERE 
    ca.ca_state IN ('NY', 'CA') 
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ch.c_customer_sk) > 5
ORDER BY 
    customer_count DESC, 
    ca.ca_city ASC
LIMIT 10 
OFFSET CASE 
    WHEN (SELECT COUNT(*) FROM customer) > 1000 THEN 20 
    ELSE 0 
END;
