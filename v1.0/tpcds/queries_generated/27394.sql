
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
age_info AS (
    SELECT 
        c.c_customer_id,
        YEAR(CURRENT_DATE) - c.c_birth_year AS age
    FROM 
        customer c
),
combined_info AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ai.age
    FROM 
        customer_info ci
    JOIN 
        age_info ai ON ci.c_customer_id = ai.c_customer_id
    WHERE 
        ci.rn = 1
)
SELECT 
    CONCAT_WS(', ', c.c_first_name, c.c_last_name, c.cd_gender, c.ca_city, c.ca_state) AS customer_details,
    COUNT(*) AS total_customers,
    AVG(c.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN ai.age > 30 THEN 1 ELSE 0 END) AS count_above_30,
    SUM(CASE WHEN ai.age <= 30 THEN 1 ELSE 0 END) AS count_below_30
FROM 
    combined_info c
JOIN 
    customer_demographics cd ON c.c_customer_id = cd.cd_demo_sk 
GROUP BY 
    customer_details
ORDER BY 
    total_customers DESC
LIMIT 10;
