
WITH address_details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
gender_demographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(*) AS gender_count,
        cd_gender
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
),
joined_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        g.gender_count,
        g.cd_gender
    FROM 
        customer c
    JOIN 
        address_details a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        gender_demographics g ON c.c_current_cdemo_sk = g.cd_demo_sk
)
SELECT 
    cd_gender,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    AVG(LENGTH(full_address)) AS avg_address_length,
    MIN(ca_zip) AS min_zip,
    MAX(ca_zip) AS max_zip
FROM 
    joined_data
GROUP BY 
    cd_gender
ORDER BY 
    customer_count DESC;
