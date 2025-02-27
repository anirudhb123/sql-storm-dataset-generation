
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        full_name,
        ca_city,
        cd_gender,
        city_rank
    FROM 
        RankedCustomers
    WHERE 
        city_rank <= 10
)
SELECT 
    ca_city,
    cd_gender,
    COUNT(*) AS customer_count,
    STRING_AGG(full_name, ', ') AS top_customers_list
FROM 
    TopCustomers
GROUP BY 
    ca_city, cd_gender
ORDER BY 
    ca_city, cd_gender;
