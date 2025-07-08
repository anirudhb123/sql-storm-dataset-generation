
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        LOWER(TRIM(ca_city)) AS city,
        UPPER(TRIM(ca_state)) AS state
    FROM 
        customer_address
),
customer_with_addresses AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        p.full_address,
        p.city,
        p.state,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses p ON c.c_current_addr_sk = p.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
)
SELECT 
    city,
    state,
    COUNT(*) AS customer_count,
    LISTAGG(c_email_address, ', ') WITHIN GROUP (ORDER BY c_email_address) AS emails
FROM 
    customer_with_addresses
GROUP BY 
    city, state
ORDER BY 
    customer_count DESC
LIMIT 10;
