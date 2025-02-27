
WITH CustomerAddresses AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip)) AS FullAddress
    FROM
        customer_address
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        TRIM(cd_purchase_estimate) AS PurchaseEstimate,
        TRIM(cd_credit_rating) AS CreditRating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer_demographics
),
DistinctAddresses AS (
    SELECT DISTINCT FullAddress
    FROM CustomerAddresses
),
AggregatedDemographics AS (
    SELECT
        cd_gender,
        COUNT(cd_demo_sk) AS TotalCustomers,
        AVG(cd_dep_count) AS AvgDependentCount
    FROM CustomerDemographics
    GROUP BY cd_gender
)
SELECT
    das.FullAddress,
    adg.cd_gender,
    adg.TotalCustomers,
    adg.AvgDependentCount
FROM
    DistinctAddresses das
LEFT JOIN AggregatedDemographics adg ON TRUE
WHERE
    das.FullAddress LIKE '%Main%' AND adg.TotalCustomers > 10
ORDER BY
    das.FullAddress, adg.TotalCustomers DESC;
