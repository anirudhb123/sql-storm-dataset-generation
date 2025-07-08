
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
EnhancedData AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(ca_city, ', ', ca_state) AS location,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || full_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || full_name
            ELSE full_name 
        END AS formal_name
    FROM CustomerData
),
AggregatedData AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        LISTAGG(formal_name, '; ') AS all_customers
    FROM EnhancedData
    GROUP BY cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    all_customers,
    SPLIT(all_customers, '; ')[0] AS first_customer,
    SPLIT(all_customers, '; ')[1] AS second_customer
FROM AggregatedData
WHERE customer_count > 1
ORDER BY customer_count DESC;
