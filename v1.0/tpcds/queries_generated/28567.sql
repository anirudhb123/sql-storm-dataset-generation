
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        CustomerInfo ci
    WHERE 
        ci.city_rank <= 10
)
SELECT 
    CONCAT(city_name, ', ', state_name) AS location,
    COUNT(full_name) AS high_value_customer_count,
    STRING_AGG(full_name, ', ') AS customer_names
FROM 
    HighValueCustomers 
GROUP BY 
    ca_city AS city_name,
    ca_state AS state_name
ORDER BY 
    high_value_customer_count DESC;
