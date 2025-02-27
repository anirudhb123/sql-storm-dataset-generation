
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state
    FROM 
        RankedCustomers
    WHERE 
        ranking <= 5
)
SELECT 
    CONCAT('Top Customers from ', ca_state, ':') AS state_info,
    STRING_AGG(CONCAT(full_name, ' - ', cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status), '; ') AS customer_details
FROM 
    TopCustomers
GROUP BY 
    ca_state
ORDER BY 
    ca_state;
