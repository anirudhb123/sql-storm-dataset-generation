
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, '')) AS FullAddress
    FROM 
        customer_address
),
CustomerNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(COALESCE(c_salutation, ''), ' ', COALESCE(c_first_name, ''), ' ', COALESCE(c_last_name, '')) AS FullName
    FROM 
        customer
),
DemoDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
AggregateData AS (
    SELECT 
        a.ca_address_sk,
        c.FullName,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        LENGTH(a.FullAddress) AS AddressLength,
        (SELECT COUNT(DISTINCT cd_demo_sk) 
         FROM customer_demographics 
         WHERE cd_purchase_estimate > d.cd_purchase_estimate) AS HigherPurchaseEstimatesCount
    FROM 
        AddressParts a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        DemoDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    AddressLength,
    AVG(cd_purchase_estimate) AS AveragePurchaseEstimate,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS FemaleCount,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS MaleCount,
    AVG(HigherPurchaseEstimatesCount) AS AvgHigherPurchaseEstimatesAbove
FROM 
    AggregateData
GROUP BY 
    AddressLength
ORDER BY 
    AddressLength;
