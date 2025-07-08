
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringProcessedInfo AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        LENGTH(a.full_address) AS address_length,
        UPPER(SUBSTRING(c.full_name, 1, 1)) AS name_initial,
        REPLACE(c.cd_marital_status, 'S', 'Single') AS marital_status
    FROM 
        AddressComponents a
    JOIN 
        CustomerInfo c ON c.c_customer_sk = a.ca_address_sk
),
AggregatedData AS (
    SELECT 
        cd_gender,
        COUNT(*) AS count_customers,
        AVG(address_length) AS avg_address_length,
        LISTAGG(marital_status, ', ') WITHIN GROUP (ORDER BY marital_status) AS marital_status_summary
    FROM 
        StringProcessedInfo
    GROUP BY 
        cd_gender
)
SELECT 
    cd_gender,
    count_customers,
    avg_address_length,
    marital_status_summary
FROM 
    AggregatedData
WHERE 
    count_customers > 10
ORDER BY 
    cd_gender;
