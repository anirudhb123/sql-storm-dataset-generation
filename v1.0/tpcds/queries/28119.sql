
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_marital_status,
        cd.cd_gender,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        c_customer_sk,
        full_name,
        ca_city,
        cd_marital_status,
        cd_gender,
        LENGTH(full_name) AS name_length,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_desc
    FROM 
        RankedCustomers 
    WHERE 
        city_rank <= 10
)
SELECT 
    ca_city,
    gender_desc,
    AVG(name_length) AS avg_name_length,
    COUNT(*) AS total_customers,
    STRING_AGG(full_name, ', ') AS customer_names
FROM 
    FilteredCustomers
GROUP BY 
    ca_city, gender_desc
ORDER BY 
    ca_city, gender_desc;
