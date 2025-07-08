
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S' 
        AND ca.ca_city IS NOT NULL
),
TopCustomers AS (
    SELECT 
        full_name,
        ca_city
    FROM 
        RankedCustomers
    WHERE 
        rn <= 10
)
SELECT 
    ca_city,
    LISTAGG(full_name, ', ') WITHIN GROUP (ORDER BY full_name) AS top_customers
FROM 
    TopCustomers
GROUP BY 
    ca_city
ORDER BY 
    ca_city;
