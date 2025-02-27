
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(ca_street_name)) AS processed_street_name,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        COUNT(pa.ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT pa.processed_street_name, ', ') AS unique_street_names,
        STRING_AGG(DISTINCT pa.full_address, '; ') AS unique_full_addresses,
        pa.ca_city,
        pa.ca_state
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        ProcessedAddresses pa ON ci.c_customer_sk = pa.ca_address_sk -- Example join condition, needs to be adjusted based on actual relations
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.cd_marital_status, pa.ca_city, pa.ca_state
)
SELECT 
    a.full_name,
    a.cd_gender,
    a.cd_marital_status,
    a.address_count,
    a.unique_street_names,
    a.unique_full_addresses,
    a.ca_city,
    a.ca_state
FROM 
    AggregatedData a
WHERE 
    a.address_count > 0
ORDER BY 
    a.ca_city, a.full_name;
