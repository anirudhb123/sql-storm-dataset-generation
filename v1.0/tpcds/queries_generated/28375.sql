
WITH detailed_customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        CONCAT(UPPER(LEFT(c.c_first_name, 1)), LOWER(SUBSTRING(c.c_first_name, 2))) AS formatted_first_name,
        CONCAT(UPPER(LEFT(c.c_last_name, 1)), LOWER(SUBSTRING(c.c_last_name, 2))) AS formatted_last_name
    FROM 
        customer c
    JOIN 
        customer_attribute ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_summary AS (
    SELECT 
        ci.c_customer_sk,
        COUNT(DISTINCT ci.ca_city) AS unique_cities,
        COUNT(*) AS total_records,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN ci.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN ci.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        detailed_customer_info ci
    GROUP BY 
        ci.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.unique_cities,
    cs.total_records,
    cs.avg_purchase_estimate,
    cs.male_count,
    cs.female_count,
    ROW_NUMBER() OVER (ORDER BY cs.avg_purchase_estimate DESC) AS rank
FROM 
    customer_summary cs
WHERE 
    cs.avg_purchase_estimate > 1000
ORDER BY 
    cs.avg_purchase_estimate DESC;
