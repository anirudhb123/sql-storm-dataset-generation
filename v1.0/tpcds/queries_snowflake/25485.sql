
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_upper
    FROM 
        customer_address
), AddressStatistics AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        AVG(street_name_length) AS avg_street_name_length, 
        LISTAGG(DISTINCT city_upper, ', ') WITHIN GROUP (ORDER BY city_upper) AS unique_cities
    FROM 
        ProcessedAddresses
    GROUP BY 
        ca_state
)
SELECT 
    a.ca_state, 
    a.address_count, 
    a.avg_street_name_length, 
    a.unique_cities,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    AddressStatistics a
JOIN 
    customer AS c ON c.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE ca_state = a.ca_state LIMIT 1)
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    a.address_count > 100
ORDER BY 
    a.address_count DESC;
