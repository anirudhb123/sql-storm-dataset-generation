
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS NumberOfOrders,
        AVG(ws.ws_net_paid_inc_tax) AS AverageOrderValue,
        COUNT(DISTINCT ws.ws_web_page_sk) AS DistinctWebPages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_id
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS CustomerCount,
        SUM(cs.TotalSales) AS TotalSales,
        AVG(cs.AverageOrderValue) AS AvgOrderValue
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
IncomeAnalysis AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_id) AS CustomerCount,
        SUM(cs.TotalSales) AS TotalSales
    FROM 
        CustomerSales cs
    JOIN 
        household_demographics hd ON cs.c_customer_id = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    ia.ib_income_band_sk,
    da.CustomerCount,
    da.TotalSales,
    ia.TotalSales AS IncomeBandTotalSales
FROM 
    DemographicAnalysis da
LEFT JOIN 
    IncomeAnalysis ia ON da.CustomerCount = ia.CustomerCount
ORDER BY 
    da.TotalSales DESC, da.cd_gender;
