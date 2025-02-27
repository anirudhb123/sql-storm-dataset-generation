
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE 
                        WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) 
                        ELSE '' 
                    END
        )) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
address_counts AS (
    SELECT 
        full_address,
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        address_parts
    GROUP BY 
        full_address, ca_city, ca_state
),
demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
total_customer AS (
    SELECT 
        COUNT(DISTINCT c_customer_sk) AS total_count
    FROM 
        customer
),
result AS (
    SELECT 
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.address_count,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count,
        tc.total_count
    FROM 
        address_counts ac
    JOIN 
        demographics d ON ac.ca_city = d.ca_city  
    CROSS JOIN 
        total_customer tc
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    address_count,
    cd_gender,
    cd_marital_status,
    customer_count,
    total_count,
    ROUND(customer_count * 100.0 / total_count, 2) AS percentage_customers
FROM 
    result
ORDER BY 
    address_count DESC, ca_city, ca_state;
