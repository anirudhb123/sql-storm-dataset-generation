
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
StringBenchmark AS (
    SELECT 
        full_name,
        CONCAT('Customer ', full_name, ' from ', ca_city, ', ', ca_state, ' with ZIP ', ca_zip) AS description,
        CHAR_LENGTH(full_name) AS name_length,
        CHAR_LENGTH(description) AS description_length
    FROM 
        CustomerInfo
    WHERE 
        rn <= 1000
), 
AggregatedInfo AS (
    SELECT 
        MIN(name_length) AS min_length,
        MAX(name_length) AS max_length,
        AVG(name_length) AS avg_length,
        MIN(description_length) AS min_desc_length,
        MAX(description_length) AS max_desc_length,
        AVG(description_length) AS avg_desc_length
    FROM 
        StringBenchmark
)

SELECT 
    CONCAT('Name Lengths - Min: ', min_length, ', Max: ', max_length, ', Avg: ', ROUND(avg_length, 2), 
           ' | Description Lengths - Min: ', min_desc_length, ', Max: ', max_desc_length, ', Avg: ', ROUND(avg_desc_length, 2)) AS benchmark_results
FROM 
    AggregatedInfo;
