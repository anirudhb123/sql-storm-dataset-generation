
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_info
    WHERE 
        rank = 1
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(full_name, '; ') AS customer_names
FROM 
    top_customers
GROUP BY 
    ca_city, 
    ca_state
ORDER BY 
    total_customers DESC, 
    avg_purchase_estimate DESC
LIMIT 10;
