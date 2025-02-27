
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS AddressCount,
        COUNT(DISTINCT ca_city) AS UniqueCityCount,
        AVG(LENGTH(ca_street_name)) AS AvgStreetNameLength
    FROM 
        customer_address 
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS CustomerCount,
        AVG(cd_dep_count) AS AvgDependents,
        SUM(cd_purchase_estimate) AS TotalPurchaseEstimate
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS TotalWebSales,
        SUM(cs_ext_sales_price) AS TotalCatalogSales,
        SUM(ss_ext_sales_price) AS TotalStoreSales
    FROM 
        date_dim 
    JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk 
    JOIN 
        catalog_sales ON d_date_sk = cs_sold_date_sk 
    JOIN 
        store_sales ON d_date_sk = ss_sold_date_sk 
    GROUP BY 
        d_year
)
SELECT 
    A.ca_state,
    A.AddressCount,
    A.UniqueCityCount,
    A.AvgStreetNameLength,
    C.cd_gender,
    C.CustomerCount,
    C.AvgDependents,
    C.TotalPurchaseEstimate,
    S.d_year,
    S.TotalWebSales,
    S.TotalCatalogSales,
    S.TotalStoreSales
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.AddressCount > 100
JOIN 
    SalesStats S ON S.TotalWebSales > 10000
ORDER BY 
    A.ca_state, C.cd_gender, S.d_year;
