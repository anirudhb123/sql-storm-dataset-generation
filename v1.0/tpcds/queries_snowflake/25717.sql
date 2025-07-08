
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') AND 
        cd.cd_marital_status = 'M'
),
TopNNames AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        name_length
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
)
SELECT 
    ca_state,
    COUNT(*) AS total_customers,
    AVG(name_length) AS avg_name_length,
    LISTAGG(full_name, ', ') AS top_names
FROM 
    TopNNames
GROUP BY 
    ca_state
ORDER BY 
    total_customers DESC;
