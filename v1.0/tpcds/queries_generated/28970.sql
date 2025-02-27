
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS TotalAddresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, '; ') AS FullAddress
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS TotalDemographics,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS EducationLevels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        SUM(ws_sales_price) AS TotalSales,
        STRING_AGG(DISTINCT ws_order_number::TEXT, ', ') AS OrderNumbers
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_ship_customer_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.TotalAddresses,
    a.FullAddress,
    d.cd_gender,
    d.cd_marital_status,
    d.TotalDemographics,
    d.EducationLevels,
    s.TotalSales,
    s.OrderNumbers
FROM 
    AddressDetails a
LEFT JOIN 
    CustomerDemographics d ON a.TotalAddresses > 0
LEFT JOIN 
    SalesData s ON s.ws_bill_customer_sk = d.cd_demo_sk
WHERE 
    d.TotalDemographics > 5
ORDER BY 
    a.ca_city, a.ca_state;
