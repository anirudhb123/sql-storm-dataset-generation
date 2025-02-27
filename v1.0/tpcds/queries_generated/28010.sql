
WITH AddressAnalysis AS (
    SELECT 
        ca.city AS City,
        COUNT(*) AS AddressCount,
        AVG(ca.gmt_offset) AS AverageGMTOffset,
        STRING_AGG(DISTINCT ca.street_name, ', ') AS DistinctStreets,
        STRING_AGG(DISTINCT CONCAT(ca.street_number, ' ', ca.street_type), '; ') AS StreetDetails
    FROM 
        customer_address ca
    GROUP BY 
        ca.city
),
CustomerAnalysis AS (
    SELECT 
        cd.gender AS Gender,
        COUNT(*) AS CustomerCount,
        AVG(cd.purchase_estimate) AS AveragePurchaseEstimate,
        STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS CustomerNames
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.education_status IN ('PhD', 'Masters')
    GROUP BY 
        cd.gender
),
SalesSummary AS (
    SELECT 
        d.d_year AS Year,
        SUM(ws.ws_ext_sales_price) AS TotalWebSales,
        SUM(cs.cs_ext_sales_price) AS TotalCatalogSales,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales,
        STRING_AGG(DISTINCT CONCAT('Year: ', d.d_year, ', Total Web Sales: ', COALESCE(ws.ws_ext_sales_price, 0)), '; ') AS SalesByYear
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    aa.City,
    aa.AddressCount,
    aa.AverageGMTOffset,
    ca.Gender,
    ca.CustomerCount,
    ca.AveragePurchaseEstimate,
    ss.Year,
    ss.TotalWebSales,
    ss.TotalCatalogSales,
    ss.TotalStoreSales
FROM 
    AddressAnalysis aa
JOIN 
    CustomerAnalysis ca ON ca.CustomerCount > 100
JOIN 
    SalesSummary ss ON ss.Year BETWEEN 2020 AND 2023
ORDER BY 
    aa.AddressCount DESC, ca.CustomerCount DESC;
