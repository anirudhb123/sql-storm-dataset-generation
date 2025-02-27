
WITH RankedSales AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_credit_rating
    FROM 
        customer_demographics
),
IncomeDistribution AS (
    SELECT 
        ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        household_demographics 
    GROUP BY 
        ib_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        r.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.cd_gender,
    tc.cd_marital_status,
    CONCAT('$', FORMAT(tc.ib_lower_bound, 0), ' - $', FORMAT(tc.ib_upper_bound, 0)) AS income_range
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
