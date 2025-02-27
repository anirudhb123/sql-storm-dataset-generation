
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        gender, 
        marital_status, 
        income_band_sk,
        COUNT(c_customer_sk) AS num_customers,
        AVG(total_sales) AS avg_sales
    FROM 
        CustomerSales
    GROUP BY 
        gender, marital_status, income_band_sk
)
SELECT 
    ss.gender,
    ss.marital_status,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    ss.num_customers,
    ss.avg_sales,
    RANK() OVER (PARTITION BY ss.gender ORDER BY ss.avg_sales DESC) AS sales_rank
FROM 
    SalesSummary ss
JOIN 
    income_band ib ON ss.income_band_sk = ib.ib_income_band_sk
WHERE 
    ss.num_customers > 10
ORDER BY 
    ss.gender, sales_rank;
