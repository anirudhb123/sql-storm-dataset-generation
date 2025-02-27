
WITH Address_Summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics_Summary AS (
    SELECT 
        cd_gender,
        COUNT(c_d.demo_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd_gender
),
String_Benchmark AS (
    SELECT 
        CONCAT('State: ', as.ca_state, ', Unique Addresses: ', as.unique_addresses, 
               ', Avg Street Name Length: ', CAST(as.avg_street_name_length AS VARCHAR),
               ', Total Customers: ', ds.customer_count, 
               ', Gender: ', ds.cd_gender) AS benchmark_string
    FROM 
        Address_Summary as
    JOIN 
        Demographics_Summary ds ON ds.customer_count > 0
)
SELECT 
    benchmark_string
FROM 
    String_Benchmark
WHERE 
    LENGTH(benchmark_string) > 100
ORDER BY 
    LENGTH(benchmark_string) DESC
LIMIT 10;
