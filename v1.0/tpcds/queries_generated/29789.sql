
WITH customer_info AS (
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
        cd.dep_count,
        cd.dep_employed_count,
        cd.dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
gender_stats AS (
    SELECT 
        ci.cd_gender,
        COUNT(*) AS total_customers,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT CASE WHEN ci.cd_marital_status = 'M' THEN ci.c_customer_sk END) AS married_customers
    FROM 
        customer_info ci
    GROUP BY 
        ci.cd_gender
),
location_stats AS (
    SELECT 
        ci.ca_state,
        COUNT(*) AS total_customers,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_info ci
    GROUP BY 
        ci.ca_state
)
SELECT 
    gs.cd_gender,
    gs.total_customers AS total_customers_gender,
    gs.avg_purchase_estimate AS avg_purchase_gender,
    ls.ca_state,
    ls.total_customers AS total_customers_state,
    ls.avg_purchase_estimate AS avg_purchase_state
FROM 
    gender_stats gs
FULL JOIN 
    location_stats ls ON 1=1
ORDER BY 
    gs.cd_gender, ls.ca_state;
