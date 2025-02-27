
WITH RECURSIVE AddressComponents AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        UPPER(ca_street_name) AS upper_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
), 
FormattedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', upper_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        rn
    FROM 
        AddressComponents
)
SELECT 
    full_address,
    COUNT(*) AS address_count,
    STRING_AGG(DISTINCT CONCAT('Record: ', ca_address_sk) ORDER BY ca_address_sk) AS addresses
FROM 
    FormattedAddresses
GROUP BY 
    full_address
HAVING 
    COUNT(*) > 1
ORDER BY 
    address_count DESC
LIMIT 10;
