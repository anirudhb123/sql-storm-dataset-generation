
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state
    FROM 
        customer_address
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS TotalCustomers,
        AVG(cd_purchase_estimate) AS AvgPurchaseEstimate,
        LISTAGG(DISTINCT ca_country, ', ') AS UniqueCountries
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
DailySales AS (
    SELECT 
        d.d_date AS SaleDate,
        SUM(ws.ws_quantity) AS TotalUnitsSold,
        SUM(ws.ws_net_paid) AS TotalNetSales,
        SUM(ws.ws_ext_ship_cost) AS TotalShippingCosts
    FROM 
        date_dim AS d
    JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    cs.cd_gender,
    cs.TotalCustomers,
    cs.AvgPurchaseEstimate,
    ds.SaleDate,
    ds.TotalUnitsSold,
    ds.TotalNetSales,
    ds.TotalShippingCosts
FROM 
    AddressDetails AS ad
JOIN 
    CustomerStats AS cs ON ad.ca_state = cs.cd_gender
JOIN 
    DailySales AS ds ON ds.SaleDate = CAST('2002-10-01' AS DATE)
WHERE 
    ad.ca_city LIKE 'San%'
ORDER BY 
    ds.TotalNetSales DESC;
