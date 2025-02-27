
WITH CombinedAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
CityAddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        AVG(address_length) AS avg_address_length
    FROM 
        CombinedAddresses
    GROUP BY 
        ca_city
)
SELECT 
    c.cd_gender,
    cad.ca_city,
    cad.address_count,
    cad.avg_address_length,
    MIN(c.c_birth_year) AS earliest_birth_year,
    MAX(c.c_birth_year) AS latest_birth_year
FROM 
    customer c
JOIN 
    CombinedAddresses cad ON c.c_current_addr_sk = cad.ca_address_sk
JOIN 
    CityAddressCounts cac ON cad.ca_city = cac.ca_city
GROUP BY 
    c.cd_gender, cad.ca_city, cad.address_count, cad.avg_address_length
ORDER BY 
    cad.address_count DESC, late_birth_year;
