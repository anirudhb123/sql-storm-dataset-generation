
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
),
CitySummary AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS total_customers,
        LISTAGG(full_name, ', ') WITHIN GROUP (ORDER BY full_name) AS customer_names
    FROM 
        RankedCustomers rc
    JOIN 
        customer_address ca ON rc.c_customer_id = ca.ca_address_id
    WHERE 
        rc.rank <= 5
    GROUP BY 
        ca.ca_city
)
SELECT 
    cs.ca_city,
    cs.total_customers,
    cs.customer_names,
    CONCAT('Total customers in ', cs.ca_city, ': ', cs.total_customers) AS city_summary
FROM 
    CitySummary cs
ORDER BY 
    cs.total_customers DESC;
