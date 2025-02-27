WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS AddressCount,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS StreetNames
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        ca_city, ca_state
),
CustomerAgeGroup AS (
    SELECT 
        CASE 
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) < 18 THEN 'Under 18'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) BETWEEN 18 AND 35 THEN '18-35'
            WHEN (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) BETWEEN 36 AND 55 THEN '36-55'
            ELSE '56 and above'
        END AS AgeGroup,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM 
        customer
    GROUP BY 
        AgeGroup
),
SalesSummary AS (
    SELECT 
        d.d_year AS SaleYear,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.AddressCount,
    ad.StreetNames,
    ag.AgeGroup,
    ag.CustomerCount,
    ss.SaleYear,
    ss.TotalSales,
    ss.OrderCount
FROM 
    AddressDetails ad
JOIN 
    CustomerAgeGroup ag ON 1=1 
JOIN 
    SalesSummary ss ON ss.SaleYear BETWEEN 1998 AND 2001 
ORDER BY 
    ad.ca_state, ad.ca_city, ag.AgeGroup, ss.SaleYear;