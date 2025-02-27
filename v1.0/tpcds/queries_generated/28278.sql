
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        ca.zip AS address_zip,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringBenchmarking AS (
    SELECT 
        address_city,
        address_state,
        address_zip,
        customer_name,
        cd_gender,
        cd_marital_status,
        LENGTH(customer_name) AS name_length,
        UPPER(customer_name) AS name_upper,
        LOWER(customer_name) AS name_lower,
        REPLACE(customer_name, ' ', '-') AS name_hyphenated
    FROM 
        AddressDetails
),
MostFrequentCities AS (
    SELECT 
        address_city,
        COUNT(*) AS city_count
    FROM 
        StringBenchmarking
    GROUP BY 
        address_city
    ORDER BY 
        city_count DESC
    LIMIT 10
)
SELECT 
    sf.city_count,
    sf.address_city,
    sb.customer_name,
    sb.name_length,
    sb.name_upper,
    sb.name_lower,
    sb.name_hyphenated
FROM 
    MostFrequentCities AS sf
JOIN 
    StringBenchmarking AS sb ON sf.address_city = sb.address_city
ORDER BY 
    sf.city_count DESC, sb.name_length ASC;
