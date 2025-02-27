
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS Total_Sales,
        AVG(ss.ss_sales_price) AS Avg_Sales_Price,
        COUNT(DISTINCT ss.ss_ticket_number) AS Total_Transactions,
        COUNT(DISTINCT ss.ss_store_sk) AS Store_Count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_id) AS Customer_Count,
        AVG(cs.Total_Sales) AS Avg_Customer_Sales,
        SUM(cs.Total_Transactions) AS Total_Transactions
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = cs.c_customer_id
    GROUP BY 
        cd.cd_gender
),
SalesMetrics AS (
    SELECT 
        ds.d_year,
        SUM(cs.Total_Sales) AS Yearly_Sales,
        AVG(cs.Avg_Sales_Price) AS Yearly_Avg_Price,
        COUNT(cs.Total_Transactions) AS Total_Transactions
    FROM 
        CustomerSales cs
    JOIN 
        date_dim ds ON ds.d_date_sk = cs.Total_Transactions
    GROUP BY 
        ds.d_year
)
SELECT 
    ds.d_year,
    ds.Yearly_Sales,
    ds.Yearly_Avg_Price,
    ds.Total_Transactions,
    ds.Yearly_Sales / NULLIF(SUM(dg.Customer_Count) OVER (), 0) AS Sales_Per_Customer,
    dg.cd_gender
FROM 
    SalesMetrics ds
JOIN 
    DemographicSummary dg ON dg.Total_Transactions = ds.Total_Transactions
WHERE 
    ds.Yearly_Sales > 1000000
ORDER BY 
    ds.d_year DESC;
