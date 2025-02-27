
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_job_estimate, 
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA'
    AND 
        cd.cd_purchase_estimate > 1000
),
TopCustomers AS (
    SELECT * 
    FROM RankedCustomers 
    WHERE city_rank <= 10
)
SELECT 
    city, 
    COUNT(*) AS customer_count, 
    STRING_AGG(c_first_name || ' ' || c_last_name, ', ') AS top_customer_names
FROM 
    TopCustomers
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC;
