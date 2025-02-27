
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown' 
        END AS gender,
        ca.ca_city AS location,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COALESCE(cd.cd_education_status, 'N/A') AS education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
counted_customers AS (
    SELECT 
        gender,
        COUNT(*) AS customer_count,
        AVG(LENGTH(full_name)) AS avg_name_length,
        STRING_AGG(DISTINCT location, ', ') AS unique_locations
    FROM 
        processed_customers
    GROUP BY 
        gender
)
SELECT 
    gender,
    customer_count,
    avg_name_length,
    unique_locations,
    CONCAT('Total customers: ', SUM(customer_count) OVER ()) AS total_customers
FROM 
    counted_customers
ORDER BY 
    customer_count DESC;
