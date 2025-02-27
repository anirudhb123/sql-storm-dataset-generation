
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress
    FROM 
        customer_address
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS CustomerCount
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
PopularCities AS (
    SELECT 
        ca_city, 
        COUNT(*) AS AddressCount
    FROM 
        customer_address
    GROUP BY 
        ca_city
    ORDER BY 
        AddressCount DESC
    LIMIT 10
)
SELECT 
    a.FullAddress, 
    g.cd_gender AS Gender, 
    g.CustomerCount AS TotalCustomers, 
    pc.AddressCount AS TotalAddressesInCity
FROM 
    AddressConcat AS a
JOIN 
    GenderStats AS g ON g.CustomerCount > 100
JOIN 
    PopularCities AS pc ON pc.ca_city = SUBSTRING_INDEX(a.FullAddress, ' ', -2)
ORDER BY 
    pc.AddressCount DESC, 
    a.FullAddress;
