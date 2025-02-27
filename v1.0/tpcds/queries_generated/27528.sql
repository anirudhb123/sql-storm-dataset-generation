
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        INITCAP(ca_street_number) AS street_num,
        INITCAP(ca_street_name) AS street_name,
        UPPER(ca_street_type) AS street_type,
        INITCAP(ca_city) AS city,
        INITCAP(ca_state) AS state,
        INITCAP(ca_country) AS country
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.street_num || ' ' || ad.street_name || ' ' || ad.street_type || ', ' || 
        ad.city || ', ' || ad.state || ', ' || ad.country AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_parts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
benchmark_data AS (
    SELECT 
        FULL_NAME,
        CD_GENDER,
        CD_MARITAL_STATUS,
        CD_EDUCATION_STATUS,
        FULL_ADDRESS,
        CHAR_LENGTH(FULL_ADDRESS) AS address_length,
        SUBSTRING(FULL_ADDRESS FROM 1 FOR 10) AS address_start
    FROM 
        customer_data
)
SELECT 
    CD_GENDER,
    CD_MARITAL_STATUS,
    AVG(address_length) AS avg_address_length,
    COUNT(*) AS total_customers,
    COUNT(DISTINCT address_start) AS unique_address_starts
FROM 
    benchmark_data
GROUP BY 
    CD_GENDER, 
    CD_MARITAL_STATUS
ORDER BY 
    avg_address_length DESC, 
    total_customers DESC;
