
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        UPPER(ca_street_name) AS upper_street_name,
        LENGTH(ca_street_name) AS street_length,
        SUBSTR(ca_street_name, 1, 5) AS street_prefix,
        REPLACE(ca_city, ' ', '_') AS city_modified
    FROM 
        customer_address
),
Gender_Demo AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        ROUND(AVG(cd_purchase_estimate), 2) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Customer_Stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.upper_street_name,
        a.street_length,
        g.gender_count,
        g.avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        Gender_Demo g ON c.c_current_cdemo_sk = g.cd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_city,
    cs.upper_street_name,
    cs.street_length,
    cs.gender_count,
    cs.avg_purchase_estimate,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    CASE 
        WHEN cs.street_length > 30 THEN 'Long Street Name'
        WHEN cs.street_length BETWEEN 15 AND 30 THEN 'Medium Street Name'
        ELSE 'Short Street Name'
    END AS street_length_category
FROM 
    Customer_Stats cs
WHERE 
    cs.gender_count > 10
ORDER BY 
    cs.avg_purchase_estimate DESC
LIMIT 100;
