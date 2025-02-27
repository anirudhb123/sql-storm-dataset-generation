
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        SUM(ws_net_profit) AS TotalProfit,
        COUNT(*) AS OrderCount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
), TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.TotalSales,
        cs.TotalProfit,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        SalesSummary cs
    JOIN 
        CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
    ORDER BY 
        cs.TotalSales DESC
    LIMIT 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.TotalSales,
    tc.TotalProfit,
    CASE 
        WHEN tc.cd_gender = 'M' THEN 'Male'
        WHEN tc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS Gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopCustomers tc
LEFT JOIN 
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk;
