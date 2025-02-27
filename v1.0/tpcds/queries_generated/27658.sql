
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        LENGTH(ca.ca_street_name) AS StreetNameLength,
        UPPER(ca.ca_country) AS CountryUpperCase
    FROM 
        customer_address ca
)
SELECT 
    cd.cd_gender,
    COUNT(DISTINCT cd.cd_demo_sk) AS CustomerCount,
    AVG(StreetNameLength) AS AvgStreetNameLength,
    STRING_AGG(DISTINCT FullAddress, ', ') AS AllAddresses,
    COUNT(DISTINCT CASE WHEN ca_state = 'CA' THEN ca_address_id END) AS CAAddressCount
FROM 
    customer_demographics cd
JOIN 
    customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    AddressDetails ad ON ad.ca_address_id = c.c_address_id
GROUP BY 
    cd.cd_gender
ORDER BY 
    CustomerCount DESC;
