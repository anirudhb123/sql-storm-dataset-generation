
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ca.ca_city IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        full_name,
        ca_city
    FROM 
        RankedCustomers
    WHERE 
        rnk <= 10
)
SELECT 
    ca.ca_city,
    STRING_AGG(fc.full_name, ', ') AS top_female_customers
FROM 
    FilteredCustomers fc
JOIN 
    customer_address ca ON fc.ca_city = ca.ca_city
GROUP BY 
    ca.ca_city
ORDER BY 
    ca.ca_city;
