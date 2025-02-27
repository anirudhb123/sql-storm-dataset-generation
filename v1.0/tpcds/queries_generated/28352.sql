
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
        full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        RankedCustomers
    WHERE 
        rank <= 5
),
AddressInfo AS (
    SELECT 
        ca.city,
        ca.state,
        c.c_customer_id,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state
),
Benchmark AS (
    SELECT 
        ai.city,
        ai.state,
        STRING_AGG(DISTINCT tc.full_name) AS top_customers,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        AddressInfo ai
    JOIN 
        TopCustomers tc ON tc.c_customer_id = c.c_customer_id
    JOIN 
        customer c ON ai.c_customer_id = c.c_customer_id
    GROUP BY 
        ai.city, ai.state
)
SELECT 
    city, 
    state, 
    top_customers, 
    total_customers
FROM 
    Benchmark
ORDER BY 
    total_customers DESC;
