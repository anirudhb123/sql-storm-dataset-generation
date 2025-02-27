
WITH AddressDetails AS (
    SELECT 
        ca_country,
        COUNT(*) AS AddressCount,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS FullAddressList
    FROM 
        customer_address
    GROUP BY 
        ca_country
),
Demographics AS (
    SELECT 
        cd_gender,
        MAX(cd_purchase_estimate) AS MaxPurchaseEstimate,
        MIN(cd_credit_rating) AS MinCreditRating,
        STRING_AGG(CONCAT(cd_demo_sk, ': ', cd_gender), ', ') AS DemoDetails
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Combined AS (
    SELECT 
        a.ca_country,
        a.AddressCount,
        a.FullAddressList,
        d.MaxPurchaseEstimate,
        d.MinCreditRating,
        d.DemoDetails
    FROM 
        AddressDetails a
    LEFT JOIN 
        Demographics d ON a.AddressCount > 100
)
SELECT 
    ca_country AS Country,
    AddressCount AS NumberOfAddresses,
    FullAddressList AS AddressConcat,
    MaxPurchaseEstimate AS HighestEstimate,
    MinCreditRating AS LowestRating,
    DemoDetails AS DemographicInformation
FROM 
    Combined
ORDER BY 
    Country;
