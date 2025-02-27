
WITH CustomerDetails AS (
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
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        CustomerDetails c
    WHERE 
        c.city_rank <= 5
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(tc.c_customer_id) AS num_top_customers,
    AVG(tc.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name) ORDER BY tc.c_last_name) AS top_customer_names
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    num_top_customers DESC, ca.ca_city;
