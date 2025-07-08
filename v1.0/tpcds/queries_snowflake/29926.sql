
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS formatted_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
JoinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.formatted_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        (d.cd_gender = 'F' AND d.cd_marital_status = 'M') OR (d.cd_gender = 'M' AND d.cd_marital_status = 'S')
),
AggregatedData AS (
    SELECT 
        COUNT(*) AS customer_count,
        LISTAGG(CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name) AS customer_names,
        formatted_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        JoinedData
    GROUP BY 
        c_first_name, c_last_name, formatted_address, ca_city, ca_state, ca_zip, ca_country
)
SELECT 
    customer_count,
    customer_names,
    formatted_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country
FROM 
    AggregatedData
ORDER BY 
    customer_count DESC
LIMIT 10;
