
WITH AddressDetails AS (
    SELECT 
        ca_state, 
        ca_city,
        ca_zip,
        COUNT(*) AS AddressCount,
        STRING_AGG(CONCAT(ca_street_name, ' ', ca_street_number, ' ', ca_street_type), ', ') AS FullAddressList
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city, ca_zip
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS CustomerCount,
        AVG(cd_dep_count) AS AverageDependents,
        STRING_AGG(cd_marital_status, ', ') AS MaritalStatusList
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_profit) AS TotalNetProfit,
        SUM(ws_quantity) AS TotalQuantitySold
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ad.ca_state,
    ad.ca_city,
    ad.ca_zip,
    ad.AddressCount,
    ad.FullAddressList,
    da.cd_gender,
    da.CustomerCount,
    da.AverageDependents,
    da.MaritalStatusList,
    ss.ws_ship_date_sk,
    ss.TotalNetProfit,
    ss.TotalQuantitySold
FROM 
    AddressDetails ad
JOIN 
    DemographicAnalysis da ON ad.ca_city = da.cd_gender
JOIN 
    SalesSummary ss ON ad.AddressCount > 10 AND ss.TotalNetProfit > 1000
ORDER BY 
    ad.ca_state, ad.ca_city;
