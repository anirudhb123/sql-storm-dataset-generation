
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        CustomerInfo
    WHERE 
        rank <= 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    STRING_AGG(full_name, ', ') AS top_customers,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON ca.ca_city = tc.ca_city AND ca.ca_state = tc.ca_state
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    customer_count DESC, avg_purchase_estimate DESC;
