
WITH AddressInfo AS (
    SELECT 
        ca.city AS City,
        ca.state AS State,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS FullAddress,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state, ca.street_number, ca.street_name, ca.street_type
),
SalesData AS (
    SELECT 
        s.s_store_name AS StoreName,
        SUM(ws.ws_quantity) AS TotalQuantitySold,
        SUM(ws.ws_sales_price) AS TotalSales,
        SUM(ws.ws_net_profit) AS TotalNetProfit
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY 
        s.s_store_name
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender AS Gender,
        cd.cd_marital_status AS MaritalStatus,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimation,
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    a.City,
    a.State,
    a.FullAddress,
    a.CustomerCount,
    s.StoreName,
    s.TotalQuantitySold,
    s.TotalSales,
    s.TotalNetProfit,
    d.Gender,
    d.MaritalStatus,
    d.AvgPurchaseEstimation,
    d.CustomerCount AS DemographicCustomerCount
FROM 
    AddressInfo a
FULL OUTER JOIN 
    SalesData s ON a.CustomerCount > 0
FULL OUTER JOIN 
    DemographicAnalysis d ON a.CustomerCount > 0
ORDER BY 
    a.City, a.State, s.StoreName, d.Gender;
