
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip,
        TRIM(ca_country) AS country
    FROM 
        customer_address
),
CustomerWithDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.d_date AS birth_date,
        d.d_month_seq AS birth_month_seq,
        a.full_address,
        a.city,
        a.state,
        a.zip,
        a.country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy AND c.c_birth_year = d.d_year
        JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
AggregatedResults AS (
    SELECT 
        city,
        state,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_count,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count,
        COUNT(CASE WHEN cd_marital_status = 'M' THEN 1 END) AS married_count,
        COUNT(CASE WHEN cd_marital_status = 'S' THEN 1 END) AS single_count
    FROM 
        CustomerWithDetails
    GROUP BY 
        city, state
)
SELECT 
    city,
    state,
    customer_count,
    avg_purchase_estimate,
    male_count,
    female_count,
    married_count,
    single_count,
    CONCAT(city, ', ', state, ' ', zip, ', ', country) AS full_location
FROM 
    AggregatedResults
ORDER BY 
    customer_count DESC
LIMIT 10;
