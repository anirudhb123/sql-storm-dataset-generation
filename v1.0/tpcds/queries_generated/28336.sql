
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', 
            TRIM(ca_street_number), 
            TRIM(ca_street_name), 
            TRIM(ca_street_type), 
            IFNULL(TRIM(ca_suite_number), '')) AS FullAddress,
        TRIM(ca_city) AS City,
        TRIM(ca_state) AS State,
        TRIM(ca_zip) AS ZipCode,
        TRIM(ca_country) AS Country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS FullName,
        cd_gender AS Gender,
        cd_marital_status AS MaritalStatus,
        cd_education_status AS EducationStatus,
        cd_purchase_estimate AS PurchaseEstimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
AddressSummary AS (
    SELECT 
        ac.City,
        ac.State,
        COUNT(*) AS AddressCount,
        AVG(LENGTH(ac.FullAddress)) AS AvgAddressLength
    FROM AddressComponents ac
    GROUP BY ac.City, ac.State
),
FinalBenchmark AS (
    SELECT 
        cd.FullName,
        cd.Gender,
        cd.MaritalStatus,
        cd.EducationStatus,
        cd.PurchaseEstimate,
        asum.AddressCount,
        asum.AvgAddressLength,
        CONCAT(asum.City, ', ', asum.State, ' ', asum.ZipCode) AS FullLocation
    FROM CustomerDetails cd
    JOIN AddressSummary asum ON cd.Gender = 'M' AND asum.AddressCount > 10
)
SELECT 
    FullName,
    Gender,
    MaritalStatus,
    EducationStatus,
    PurchaseEstimate,
    AddressCount,
    AvgAddressLength,
    FullLocation
FROM FinalBenchmark
ORDER BY PurchaseEstimate DESC, AverageLength DESC
LIMIT 100;
