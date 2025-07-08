
WITH AddressAnalysis AS (
    SELECT
        ca_city,
        COUNT(*) AS TotalAddresses,
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY ca_street_number) AS FullAddresses,
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
    CONCAT('In ', fb.ca_city, ', there are ', fb.TotalAddresses, ' addresses, including: ', fb.FullAddresses) AS AddressInfo,
    CONCAT('Gender: ', fb.cd_gender, ', Total Dependents: ', fb.TotalDependents, ', Avg Purchase Estimate: $', fb.AvgPurchaseEstimate, ', Highest Credit Rating: ', fb.HighestCreditRating) AS CustomerInfo
FROM
    FinalBenchmark fb;
