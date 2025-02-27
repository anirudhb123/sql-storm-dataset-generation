
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS Total_Web_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Order_Count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesByDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(cs.Total_Web_Sales) AS Total_Web_Sales_By_Demo,
        AVG(cs.Order_Count) AS Avg_Orders_Per_Customer
    FROM 
        CustomerSales AS cs
    JOIN 
        customer_demographics AS cd ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk
),
DemographicsIncomeBand AS (
    SELECT 
        hd.hd_income_band_sk,
        SUM(sbd.Total_Web_Sales_By_Demo) AS Total_Web_Sales_By_Income_Band,
        AVG(sbd.Avg_Orders_Per_Customer) AS Avg_Orders_Per_Customer_Income_Band
    FROM 
        SalesByDemographics AS sbd
    JOIN 
        household_demographics AS hd ON sbd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    di.Total_Web_Sales_By_Income_Band,
    di.Avg_Orders_Per_Customer_Income_Band
FROM 
    income_band AS ib
LEFT JOIN 
    DemographicsIncomeBand AS di ON ib.ib_income_band_sk = di.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
