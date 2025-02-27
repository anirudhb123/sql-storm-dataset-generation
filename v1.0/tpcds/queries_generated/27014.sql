
WITH StringBenchmark AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length,
        REPLACE(REPLACE(REPLACE(full_address, ' ', ''), ',', ''), '-', '') AS address_no_spaces
    FROM 
        customer_address
), StringAnalysis AS (
    SELECT 
        address_length,
        COUNT(*) AS num_addresses,
        AVG(address_length) AS avg_length,
        MAX(address_length) AS max_length,
        MIN(address_length) AS min_length
    FROM 
        StringBenchmark
    GROUP BY 
        address_length
)
SELECT 
    s.address_length, 
    s.num_addresses, 
    s.avg_length, 
    s.max_length, 
    s.min_length,
    COUNT(DISTINCT d.d_date_id) AS unique_dates,
    SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
FROM 
    StringAnalysis s
JOIN 
    customer ON s.address_length BETWEEN 1 AND 100
JOIN 
    customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = CURRENT_DATE
GROUP BY 
    s.address_length, s.num_addresses, s.avg_length, s.max_length, s.min_length
ORDER BY 
    s.avg_length DESC;
