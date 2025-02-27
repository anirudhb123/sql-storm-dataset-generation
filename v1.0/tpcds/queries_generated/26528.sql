
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cad.ca_city,
        cad.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
    WHERE 
        cad.ca_state IN ('CA', 'TX', 'NY') 
        AND cd.cd_purchase_estimate > 1000
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cad.ca_city,
        cad.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        ranked_customers c
    WHERE 
        c.rnk <= 10
)
SELECT 
    tc.full_name,
    tc.ca_city,
    tc.ca_state,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate
FROM 
    top_customers tc
ORDER BY 
    tc.ca_state, 
    tc.cd_purchase_estimate DESC;
