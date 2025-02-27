
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS FullAddress,
        UPPER(ca_city) AS UpperCity,
        LOWER(ca_state) AS LowerState,
        SUBSTR(ca_zip, 1, 5) AS ShortZip
    FROM customer_address
),
FilteredAddresses AS (
    SELECT 
        FullAddress,
        UpperCity,
        LowerState,
        ShortZip
    FROM ProcessedAddresses
    WHERE UpperCity LIKE '%NEW%'
)
SELECT 
    COUNT(*) AS AddressCount,
    MAX(LENGTH(FullAddress)) AS MaxAddressLength,
    MIN(LENGTH(FullAddress)) AS MinAddressLength,
    AVG(LENGTH(FullAddress)) AS AvgAddressLength,
    STRING_AGG(FullAddress, ', ') AS SampleAddresses
FROM FilteredAddresses;
