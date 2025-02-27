
WITH enriched_customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
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
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS full_name_hyphenated,
        CONCAT(c.c_first_name, ' ', c.c_last_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
purchase_metrics AS (
    SELECT 
        ci.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid) AS total_spent,
        AVG(ss.ss_net_paid) AS avg_purchase_value
    FROM 
        enriched_customer_info ci
    JOIN 
        store_sales ss ON ci.c_customer_id = ss.ss_customer_sk
    GROUP BY 
        ci.c_customer_id
),
gender_purchase_stats AS (
    SELECT 
        ci.cd_gender,
        COUNT(pm.total_purchases) AS num_customers,
        SUM(pm.total_spent) AS total_spent_by_gender,
        AVG(pm.avg_purchase_value) AS avg_spent_per_customer
    FROM 
        purchase_metrics pm
    JOIN 
        enriched_customer_info ci ON pm.c_customer_id = ci.c_customer_id
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gps.cd_gender,
    gps.num_customers,
    gps.total_spent_by_gender,
    gps.avg_spent_per_customer,
    ROW_NUMBER() OVER (ORDER BY gps.total_spent_by_gender DESC) AS rank
FROM 
    gender_purchase_stats gps
ORDER BY 
    gps.total_spent_by_gender DESC;
