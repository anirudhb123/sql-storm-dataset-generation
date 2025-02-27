
WITH enriched_customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
filtered_customers AS (
    SELECT 
        full_name,
        ca_city,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        enriched_customer_info
    WHERE 
        city_rank <= 10 AND cd_gender = 'M'
)
SELECT 
    ca_city,
    COUNT(*) AS male_customer_count,
    STRING_AGG(full_name, ', ') AS male_customer_names,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
FROM 
    filtered_customers
GROUP BY 
    ca_city
ORDER BY 
    male_customer_count DESC;
