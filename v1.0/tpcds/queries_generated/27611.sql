
WITH AddressAnalysis AS (
    SELECT
        ca_city,
        COUNT(*) AS TotalAddresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS FullAddresses,
        COUNT(DISTINCT ca_zip) AS DistinctZipCodes
    FROM
        customer_address
    GROUP BY
        ca_city
),
CustomerAnalysis AS (
    SELECT
        cd_gender,
        SUM(cd_dep_count) AS TotalDependents,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        MAX(cd_credit_rating) AS HighestCreditRating
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
FinalBenchmark AS (
    SELECT
        aa.ca_city,
        aa.TotalAddresses,
        aa.FullAddresses,
        aa.DistinctZipCodes,
        ca.cd_gender,
        ca.TotalDependents,
        ca.AvgPurchaseEstimate,
        ca.HighestCreditRating
    FROM
        AddressAnalysis aa
    JOIN
        CustomerAnalysis ca ON aa.TotalAddresses > 100
)
SELECT
    CONCAT('In ', ca.ca_city, ', there are ', ca.TotalAddresses, ' addresses, including: ', ca.FullAddresses) AS AddressInfo,
    CONCAT('Gender: ', ca.cd_gender, ', Total Dependents: ', ca.TotalDependents, ', Avg Purchase Estimate: $', CA.AvgPurchaseEstimate, ', Highest Credit Rating: ', ca.HighestCreditRating) AS CustomerInfo
FROM
    FinalBenchmark ca;
