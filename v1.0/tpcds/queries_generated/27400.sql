
WITH AddressDetails AS (
    SELECT 
        ca.city AS AddressCity,
        ca.state AS AddressState,
        LENGTH(ca.street_name) AS StreetNameLength,
        LOWER(ca.street_name) AS LoweredStreetName
    FROM 
        customer_address ca
),
GenderDemographics AS (
    SELECT 
        cd.gender AS CustomerGender,
        COUNT(c.customer_sk) AS CustomerCount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender
),
SalesSummary AS (
    SELECT 
        w.warehouse_id AS WarehouseID,
        SUM(ws.ext_sales_price) AS TotalSales,
        AVG(ws.net_profit) AS AverageProfit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    GROUP BY 
        w.warehouse_id
)
SELECT 
    ad.AddressCity,
    ad.AddressState,
    gd.CustomerGender,
    gd.CustomerCount,
    ss.WarehouseID,
    ss.TotalSales,
    ss.AverageProfit
FROM 
    AddressDetails ad
JOIN 
    GenderDemographics gd ON 1=1  -- Cross join to associate all demographic data with all address details
JOIN 
    SalesSummary ss ON 1=1  -- Cross join to associate all sales summary data
WHERE 
    ad.StreetNameLength > 20
ORDER BY 
    ss.TotalSales DESC, 
    gd.CustomerCount ASC;
