
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        COUNT(c_customer_id) * 1.0 / NULLIF(COUNT(DISTINCT c_customer_id), 0) AS avg_orders_per_customer
    FROM 
        customer_info
    GROUP BY 
        ca_city, ca_state
),
gender_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_id) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_info ci
    JOIN 
        customer_demographics cd ON ci.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
student_count AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_college_count) AS college_count
    FROM 
        customer_info ci
    JOIN 
        customer_demographics cd ON ci.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    asum.ca_city,
    asum.ca_state,
    asum.total_customers,
    SUM(gd.gender_count) AS gender_count,
    SUM(gd.avg_purchase_estimate) AS avg_purchase_estimate,
    COALESCE(stu.college_count, 0) AS college_students
FROM 
    address_summary asum
LEFT JOIN 
    gender_summary gd ON asum.total_customers > 0
LEFT JOIN 
    student_count stu ON gd.cd_gender IS NOT NULL
GROUP BY 
    asum.ca_city, asum.ca_state, asum.total_customers
ORDER BY 
    asum.ca_state, asum.ca_city;
