
WITH AddressDetails AS (
    SELECT 
        ca.cust_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS FullAddress,
        SUBSTRING(ca.ca_city, 1, 15) AS ShortCity,
        ca.ca_state,
        ca.ca_zip,
        COUNT(*) OVER (PARTITION BY ca.ca_state) AS StateCount
    FROM 
        customer_address ca
),

DemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate >= 1000 AND cd.cd_purchase_estimate < 5000 THEN 'Medium'
            ELSE 'High'
        END AS PurchaseEstimateBand
    FROM 
        customer_demographics cd
)

SELECT 
    ad.FullAddress,
    ad.ShortCity,
    ad.ca_state,
    ad.ca_zip,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.PurchaseEstimateBand,
    COUNT(ad.cust_sk) AS CustomerCount,
    SUM(dd.cd_purchase_estimate) AS TotalPurchaseEstimate
FROM 
    AddressDetails ad
JOIN 
    DemographicDetails dd ON ad.cust_sk = dd.cd_demo_sk
WHERE 
    LENGTH(ad.FullAddress) >= 10 -- Filter based on address length
GROUP BY 
    ad.FullAddress, ad.ShortCity, ad.ca_state, ad.ca_zip, dd.cd_gender, dd.cd_marital_status, dd.PurchaseEstimateBand
ORDER BY 
    TotalPurchaseEstimate DESC, CustomerCount DESC
LIMIT 100;
