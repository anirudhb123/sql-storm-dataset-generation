
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT 
        full_name, 
        ca_city, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM 
        RankedCustomers
    WHERE 
        purchase_rank <= 10
),
CitySummary AS (
    SELECT 
        ca_city, 
        COUNT(*) AS customer_count,
        LISTAGG(full_name, ', ') WITHIN GROUP (ORDER BY full_name) AS customer_names
    FROM 
        HighValueCustomers
    GROUP BY 
        ca_city
)
SELECT 
    cs.ca_city,
    cs.customer_count,
    cs.customer_names,
    CONCAT('Total High Value Customers in ', cs.ca_city, ': ', cs.customer_count) AS summary
FROM 
    CitySummary cs
ORDER BY 
    cs.customer_count DESC;
