
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_country) AS country_upper
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        ADDR.full_address,
        ADDR.city_state_zip,
        ADDR.street_name_length,
        ADDR.country_upper
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressComponents ADDR ON c.c_current_addr_sk = ADDR.ca_address_sk
),
AggregatedData AS (
    SELECT 
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS customer_count,
        AVG(cd.street_name_length) AS avg_street_name_length,
        LISTAGG(DISTINCT cd.city_state_zip, ', ') AS unique_locations
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT 
    gender,
    marital_status,
    customer_count,
    ROUND(avg_street_name_length, 2) AS avg_street_name_length,
    unique_locations
FROM 
    AggregatedData
WHERE 
    customer_count > 10
ORDER BY 
    gender, 
    marital_status;
