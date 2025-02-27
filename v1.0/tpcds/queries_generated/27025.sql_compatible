
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
AddressSummary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS total_customers,
        STRING_AGG(DISTINCT tc.full_name, ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        TopCustomers tc ON c.c_customer_id = tc.c_customer_id
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    ca_state,
    SUM(total_customers) AS total_customers_per_state,
    STRING_AGG(ca_city || ' (' || total_customers || '): ' || customer_names, '; ') AS city_summary
FROM 
    AddressSummary
GROUP BY 
    ca_state
ORDER BY 
    total_customers_per_state DESC;
