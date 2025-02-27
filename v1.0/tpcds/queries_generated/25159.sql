
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) AS CityRank
    FROM customer_address
    WHERE ca_state = 'CA'
),
RichestDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate > 100000
),
CombinedData AS (
    SELECT 
        r.ca_address_sk,
        r.ca_city,
        r.ca_state,
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM RankedAddresses r
    JOIN RichestDemographics d ON r.CityRank = 1
)
SELECT 
    ca.ca_city AS City, 
    COUNT(DISTINCT ca.ca_address_sk) AS AddressCount, 
    AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate,
    STRING_AGG(DISTINCT cd.cd_gender) AS Genders,
    STRING_AGG(DISTINCT cd.cd_marital_status) AS MaritalStatuses,
    STRING_AGG(DISTINCT cd.cd_education_status) AS EducationStatus
FROM customer_address ca
JOIN CombinedData cd ON ca.ca_address_sk = cd.ca_address_sk
GROUP BY ca.ca_city
ORDER BY AddressCount DESC, AvgPurchaseEstimate DESC;
