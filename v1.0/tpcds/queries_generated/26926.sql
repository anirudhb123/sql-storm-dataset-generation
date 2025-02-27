
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
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
formatted_details AS (
    SELECT 
        c_customer_id,
        full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || full_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || full_name
            ELSE 'Customer ' || full_name
        END AS formatted_name,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        ca_country,
        gender_rank
    FROM 
        customer_info
),
aggregated_info AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS total_married,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS total_single,
        STRING_AGG(formatted_name, ', ') AS customer_names
    FROM 
        formatted_details
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    ca_city,
    ca_state,
    total_customers,
    total_married,
    total_single,
    customer_names
FROM 
    aggregated_info
WHERE 
    total_customers > 10
ORDER BY 
    total_customers DESC;
