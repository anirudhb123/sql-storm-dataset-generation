
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS number_of_customers,
        STRING_AGG(full_name, ', ') AS customer_names
    FROM 
        customer_info
    GROUP BY 
        ca_state
),
purchase_summary AS (
    SELECT 
        ci.ca_state,
        AVG(ci.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_info ci
    GROUP BY 
        ci.ca_state
)
SELECT 
    a.ca_state,
    a.number_of_customers,
    a.customer_names,
    p.average_purchase_estimate
FROM 
    address_summary a
JOIN 
    purchase_summary p ON a.ca_state = p.ca_state
ORDER BY 
    a.number_of_customers DESC;
