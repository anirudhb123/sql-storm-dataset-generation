
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city,
        ca.ca_state, 
        ca.ca_zip, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.full_name,
        c.ca_city,
        c.ca_state,
        c.ca_zip,
        c.cd_gender,
        c.cd_marital_status
    FROM 
        CustomerInfo c
    WHERE 
        c.rn = 1
        AND c.cd_gender = 'F'
)
SELECT 
    f.ca_city, 
    f.ca_state,
    COUNT(f.customer_id) AS customer_count,
    LISTAGG(f.full_name, ', ') AS customer_names
FROM 
    FilteredCustomers f
GROUP BY 
    f.ca_city, 
    f.ca_state
HAVING 
    COUNT(f.customer_id) > 1
ORDER BY 
    customer_count DESC;
