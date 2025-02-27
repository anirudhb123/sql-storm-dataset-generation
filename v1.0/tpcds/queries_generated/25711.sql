
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
),
AggregateAddress AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS customer_count,
        STRING_AGG(RankedCustomers.customer_full_name, ', ') AS customers_list
    FROM 
        RankedCustomers
    JOIN 
        customer_address ca ON RankedCustomers.c_customer_id = ca.ca_address_id
    WHERE 
        RankedCustomers.rn <= 5
    GROUP BY 
        ca.ca_state
)
SELECT 
    a.ca_state,
    a.customer_count,
    a.customers_list,
    REPLACE(a.customers_list, ' ', '-') AS customers_with_hyphen,
    LENGTH(a.customers_list) AS total_length_of_customers_list,
    SUBSTRING(a.customers_list FROM 1 FOR 20) AS first_20_characters
FROM 
    AggregateAddress a
WHERE 
    a.customer_count > 10
ORDER BY 
    a.customer_count DESC;
