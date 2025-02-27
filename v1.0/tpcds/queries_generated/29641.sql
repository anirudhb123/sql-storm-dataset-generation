
WITH AddressSummary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS AddressCount, 
        STRING_AGG(ca_city, ', ') AS UniqueCities,
        COUNT(ca_zip) AS ZipCount,
        SUM(CASE WHEN ca_street_type ILIKE '%St%' THEN 1 ELSE 0 END) AS StStreetCount
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerSummary AS (
    SELECT 
        cd_gender,
        CD_MARITAL_STATUS,
        COUNT(DISTINCT c_customer_id) AS CustomerCount,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS CreditRatings
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d.d_year, 
        STRING_AGG(DISTINCT CASE WHEN ws.web_site_sk IS NOT NULL THEN 'Web' ELSE 'Store' END, ', ') AS SalesChannels,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalWebSales,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS TotalStoreSales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    a.ca_state, 
    a.AddressCount, 
    a.UniqueCities, 
    a.ZipCount, 
    a.StStreetCount,
    c.cd_gender, 
    c.cd_marital_status, 
    c.CustomerCount, 
    c.AvgPurchaseEstimate, 
    c.CreditRatings,
    s.d_year,
    s.SalesChannels, 
    s.TotalWebSales,
    s.TotalStoreSales
FROM 
    AddressSummary a
JOIN 
    CustomerSummary c ON a.AddressCount > 100
JOIN 
    SalesSummary s ON s.TotalWebSales + s.TotalStoreSales > 10000
ORDER BY 
    a.ca_state, c.CustomerCount DESC, s.d_year DESC;
