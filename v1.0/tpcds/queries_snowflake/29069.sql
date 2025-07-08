
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
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
        customer_details
    WHERE 
        rank <= 10
),
aggregated_data AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_details
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state,
    a.total_customers,
    a.avg_purchase_estimate,
    LISTAGG(b.full_name, ', ') WITHIN GROUP (ORDER BY b.full_name) AS top_customers
FROM 
    aggregated_data a
LEFT JOIN 
    top_customers b ON a.ca_state = b.ca_state
GROUP BY 
    a.ca_state, a.total_customers, a.avg_purchase_estimate
ORDER BY 
    a.total_customers DESC;
